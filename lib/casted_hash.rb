class CastedHash < Hash
  VERSION = "0.8.4"

  def initialize(constructor = {}, cast_proc = nil)
    raise ArgumentError, "`cast_proc` required" unless cast_proc

    @cast_proc = cast_proc
    @casting_keys = Set.new

    if constructor.is_a?(CastedHash)
      @casted_keys = constructor.instance_variable_get(:@casted_keys).dup
      super()
      update(constructor)
    elsif constructor.is_a?(Hash)
      @casted_keys = Set.new
      super()
      update(constructor)
    else
      @casted_keys = Set.new
      super(constructor)
    end
  end

  alias_method :regular_reader, :[] unless method_defined?(:regular_reader)

  def transform_keys
    return enum_for(:transform_keys) unless block_given?
    result = dup
    each_key do |key|
      result[yield(key)] = regular_reader(key)
    end
    result
  end

  def [](key)
    cast! convert_key(key)
  end

  def fetch(key, *extras)
    key = convert_key(key)
    value = cast!(key)

    if value.nil?
      super(key, *extras)
    else
      value
    end
  end

  alias_method :regular_writer, :[]= unless method_defined?(:regular_writer)

  def []=(key, value)
    key = convert_key(key)
    uncast! key
    regular_writer(key, value)
  end

  alias_method :store, :[]=

  def merge(hash)
    self.dup.update(hash)
  end

  def update(other_hash)
    return self if other_hash.empty?

    other_hash.each_pair do |key, value|
      converted_key = convert_key(key)

      regular_writer converted_key, value

      if other_hash.is_a?(CastedHash) && other_hash.casted?(key)
        casted!(key, true)
      elsif casted?(key)
        uncast!(converted_key)
      end
    end

    self
  end

  alias_method :merge!, :update

  def key?(key, converted = false)
    key = convert_key(key) unless converted
    super(key)
  end

  alias_method :include?, :key?
  alias_method :has_key?, :key?
  alias_method :member?, :key?

  def values_at(*indices)
    indices.collect {|key| self[convert_key(key)]}
  end

  def dup
    duplicate = super
    instance_variables.each do |instance_variable|
      duplicate.instance_variable_set(instance_variable, instance_variable_get(instance_variable).dup)
    end
    duplicate
  end

  def delete(key)
    key = convert_key(key)
    uncast! key
    super(key)
  end

  def values
    cast_all!
    super
  end

  def each
    cast_all!
    super
  end

  def casted_hash
    cast_all!
    self
  end

  def casted?(key, converted = false)
    key = convert_key(key) unless converted
    @casted_keys.include?(key)
  end

  def to_hash
    Hash.new.tap do |hash|
      keys.each do |key|
        hash[key] = regular_reader(key)
      end
    end
  end

  def casted
    Hash.new.tap do |hash|
      @casted_keys.each do |key|
        hash[key] = regular_reader(key)
      end
    end
  end

  def casted!(keys, converted = false)
    keys = [keys] unless keys.is_a?(Array)
    keys.each do |key|
      key = convert_key(key) unless converted
      @casted_keys << key if key?(key, converted)
    end
  end

protected

  def uncast!(*keys)
    @casted_keys.delete *keys
  end

  def cast!(key)
    return unless key?(key, true)
    return regular_reader(key) if casted?(key, true)
    raise SystemStackError, "already casting #{key}" if casting?(key)

    casting! key

    value = if @cast_proc.arity == 1
      @cast_proc.call regular_reader(key)
    elsif @cast_proc.arity == 2
      @cast_proc.call self, regular_reader(key)
    elsif @cast_proc.arity == 3
      @cast_proc.call self, key, regular_reader(key)
    else
      @cast_proc.call
    end

    value = regular_writer(key, value)

    casted! key, true

    value
  ensure
    @casting_keys.delete key
  end

  def casting!(key)
    @casting_keys << key
  end

  def casting?(key)
    @casting_keys.include?(key)
  end

  def cast_all!
    keys.each{|key| cast! key}
  end

  def convert_key(key)
    key.kind_of?(Symbol) ? key.to_s : key
  end

end
