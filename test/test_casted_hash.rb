require 'helper'

describe CastedHash do

  it "is able to define a cast method" do
    hash = CastedHash.new({:foo => 1}, lambda { |x| x.to_s })

    hash[:bar] = 1
    assert_equal "1", hash[:bar]

    hash[:bar] = 2
    assert_equal "2", hash[:bar]

    hash.store :bar, 3
    assert_equal "3", hash[:bar]
  end

  it "does not loop when refering to itself" do
    @hash = CastedHash.new({:a => 1}, lambda {|x| @hash[:a] + 1 })
    error = assert_raises(SystemStackError) do
      @hash[:a]
    end
    assert_equal "already casting a", error.message
    assert_empty @hash.casted
    assert !@hash.casted?(:a)
    assert !@hash.casting?(:a)
  end

  it "can check size without casting" do
    hash = CastedHash.new({:a => 1, :b => 2}, lambda {|x| x + 10 })
    assert hash.any?
    assert_empty hash.casted
  end

  it "casts when expected" do
    hash = CastedHash.new({:a => 1, :b => 2}, lambda {|x| x + 10 })
    assert !hash.casted?(:a)
    assert !hash.casted?(:b)

    assert_equal 11, hash[:a]

    assert hash.casted?(:a)
    assert !hash.casted?(:b)
  end

  it "responds to any? and empty?" do
    hash = CastedHash.new({}, lambda {})
    assert hash.empty?
    assert !hash.any?

    hash = CastedHash.new({:foo => "bar"}, lambda {})
    assert !hash.empty?
    assert hash.any?
  end

  it "only casts once" do
    hash = CastedHash.new({:foo => 1}, lambda { |x| x + 1 })

    assert_equal 2, hash[:foo]
    assert_equal 2, hash[:foo]

    hash[:bar] = 123
    assert_equal 124, hash[:bar]
    assert_equal 124, hash[:bar]
  end

  it "is able to fetch all casted values" do
    hash = CastedHash.new({:a => 1, :b => 10, :c => 100}, lambda { |x| x * 10 })
    assert_equal [10, 100, 1000], hash.values
  end

  it "loops through casted values" do
    hash = CastedHash.new({:a => 1, :b => 2}, lambda { |x| "processed: #{x}" })
    map = []

    hash.each do |key, value|
      map << value
    end

    assert_equal ["processed: 1", "processed: 2"], map
  end

  it "deletes values" do
    hash = CastedHash.new({:a => 1, :b => 2}, lambda {|x| x + 10 })
    hash.delete(:b)
    assert_equal({"a" => 11}, hash.casted_hash)
  end

  describe "merge" do
    it "merges values" do
      hash = CastedHash.new({:a => 1, :b => 2}, lambda {|x| x + 10 })
      assert_equal 11, hash[:a]
      assert_equal 12, hash[:b]

      hash = hash.merge({:a => 3})

      assert_equal 13, hash[:a]
      assert_equal 12, hash[:b]

      assert_equal hash, hash.merge({})
    end

    it "leaves original hash alone" do
      hash = CastedHash.new({:a => 1, :b => 2}, lambda {|x| x + 10 })
      new_hash = hash.merge({:c => 3})

      assert_equal ['a', 'b', 'c'], new_hash.keys
      assert_equal ['a', 'b'], hash.keys
    end

    it "takes over scope when merging two casted hashes" do
      hash1 = CastedHash.new({:a => 1, :b => 2, :z => 0}, lambda {|x| x + 10 })
      hash2 = CastedHash.new({:a => 2, :c => 3, :d => 4}, lambda {|x| x + 100 })

      assert_equal 11, hash1[:a]
      assert_equal 12, hash1[:b]
      assert hash1.casted?(:a)
      assert hash1.casted?(:b)

      assert_equal 104, hash2[:d]
      assert hash2.casted?(:d)
      assert !hash2.casted?(:a)

      hash3 = hash1.merge hash2
      assert_equal 10, hash3[:z]
      assert hash3.casted?(:z)
      assert !hash1.casted?(:z)

      assert_equal ["a", "b", "c", "d", "z"], hash3.keys.sort
      assert !hash3.casted?(:a) # overwritten with uncasted value
      assert hash3.casted?(:b) # not overwritten, still casted
      assert !hash3.casted?(:c) # overwritten with uncasted value
      assert hash3.casted?(:d) # overwritten with casted value

      assert_equal 12, hash3[:a]
      assert_equal 12, hash3[:b]
      assert_equal 13, hash3[:c]
      assert_equal 104, hash3[:d] # already casted
    end

    it "doesn't uncast when merging same value" do
      hash1 = CastedHash.new({:a => 1, :b => 2}, lambda {|x| x + 1})
      assert_equal 2, hash1[:a]

      hash1.merge!(hash1)

      assert hash1.casted?(:a)
      assert !hash1.casted?(:b)
    end

    it "does not cast all values when merging hashes" do
      hash = CastedHash.new({:a => 1, :b => 2}, lambda {|x| x + 10 })
      hash = hash.merge :c => 3

      assert !hash.casted?(:a)
      assert !hash.casted?(:b)
      assert !hash.casted?(:c)

      other_hash = CastedHash.new({:c => 1, :d => 2}, lambda {|x| x + 10 })
      hash = hash.merge other_hash

      assert !hash.casted?(:a)
      assert !hash.casted?(:b)
      assert !hash.casted?(:c)
      assert !other_hash.casted?(:c)
      assert !other_hash.casted?(:d)
    end
  end

  describe "merge!" do
    it "merge!s values" do
      hash = CastedHash.new({:a => 1, :b => 2}, lambda {|x| x + 10 })
      assert_equal 11, hash[:a]
      assert_equal 12, hash[:b]

      hash.merge!({:a => 3})

      assert_equal 13, hash[:a]
      assert_equal 12, hash[:b]
    end

    it "takes over scope when merging two casted hashes" do
      hash1 = CastedHash.new({:a => 1, :b => 2}, lambda {|x| x + 10 })
      hash2 = CastedHash.new({:c => 3, :d => 4}, lambda {|x| x + 100 })

      assert_equal 11, hash1[:a]
      assert_equal 12, hash1[:b]
      assert hash1.casted?(:a)
      assert hash1.casted?(:b)

      hash1.merge! hash2

      assert_equal ["a", "b", "c", "d"], hash1.keys
      assert hash1.casted?(:a)
      assert hash1.casted?(:b)
      assert !hash1.casted?(:c)
      assert !hash1.casted?(:d)

      assert_equal 11, hash1[:a]
      assert_equal 12, hash1[:b]
      assert_equal 13, hash1[:c]
      assert_equal 14, hash1[:d]
    end

    it "does not cast all values when merging hashes" do
      hash = CastedHash.new({:a => 1, :b => 2}, lambda {|x| x + 10 })
      hash.merge! :c => 3

      assert !hash.casted?(:a)
      assert !hash.casted?(:b)
      assert !hash.casted?(:c)

      other_hash = CastedHash.new({:c => 1, :d => 2}, lambda {|x| x + 10 })
      hash.merge! other_hash

      assert !hash.casted?(:a)
      assert !hash.casted?(:b)
      assert !hash.casted?(:c)
      assert !other_hash.casted?(:c)
      assert !other_hash.casted?(:d)
    end
  end

  it "does not add all requested values" do
    hash = CastedHash.new({:a => 1, :b => 2}, lambda {|x|x + 1})
    assert_equal 2, hash.fetch(:a)

    assert_nil hash[:undefined_key]
    assert_equal ["a", "b"], hash.keys

    assert_raises(KeyError) do
      hash.fetch('another_undefined_key')
    end

    assert_equal '123', hash.fetch('another_undefined_key', '123')
    assert_equal ["a", "b"], hash.keys
  end

  it "allows access to 'raw' hash" do
    hash = CastedHash.new({:a => 1, :b => 2}, lambda {|x|x + 1})
    assert_equal Hash, hash.to_hash.class
    assert_equal({"a" => 1, "b" => 2}, hash.to_hash)
    assert_equal 2, hash.fetch(:a)
    assert_equal({"a" => 2, "b" => 2}, hash.to_hash)
    assert_equal 3, hash.fetch(:b)
    assert_equal({"a" => 2, "b" => 3}, hash.to_hash)
  end

  it "allows access to casted keys only" do
    hash = CastedHash.new({:a => 1, :b => 2}, lambda {|x|x + 1})
    assert_equal Hash, hash.casted.class
    assert_equal({}, hash.casted)
    assert_equal 2, hash.fetch(:a)
    assert_equal({"a" => 2}, hash.casted)
    assert_equal 3, hash.fetch(:b)
    assert_equal({"a" => 2, "b" => 3}, hash.casted)
  end

  it "allows bypassing of casting" do
    hash = CastedHash.new({:a => 1, :b => 2, :c => 3}, lambda {|x|x + 1})
    hash.casted! "a", :b
    assert_equal 1, hash[:a]
    assert_equal 2, hash[:b]
    assert_equal 4, hash[:c]
  end
end
