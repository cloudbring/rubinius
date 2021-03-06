class Array
  attr_accessor :total
  attr_accessor :tuple
  attr_accessor :start

  alias_method :size,   :total
  alias_method :length, :total

  def self.allocate
    Ruby.primitive :array_allocate
    raise PrimitiveFailure, "Array.allocate primitive failed"
  end

  def self.coerce_into_array(obj)
    return [obj] unless obj

    return obj.to_ary if obj.respond_to?(:to_ary)

    # Just call #to_a, which wraps the reciever in an
    # array if it's not one.
    return obj.to_a
  end

  # THIS MUST NOT BE REMOVED. the kernel requires a simple
  # Array#[] to work while parts of the kernel boot.
  def [](idx)
    at(idx)
  end

  def []=(idx, ent)
    Ruby.check_frozen

    if idx >= @tuple.fields
      new_tuple = Rubinius::Tuple.new(idx + 10)
      new_tuple.copy_from @tuple, @start, @total, 0
      @tuple = new_tuple
    end

    @tuple.put @start + idx, ent
    if idx >= @total - 1
      @total = idx + 1
    end
    return ent
  end

  # Returns the element at the given index. If the
  # index is negative, counts from the end of the
  # Array. If the index is out of range, nil is
  # returned. Slightly faster than +Array#[]+
  def at(idx)
    idx = @total + idx if idx < 0
    return nil if idx > @total
    @tuple[@start + idx]
  end

  # Passes each element in the Array to the given block
  # and returns self.
  def each
    return to_enum(:each) unless block_given?

    i = @start
    total = i + @total
    tuple = @tuple

    while i < total
      yield tuple.at(i)
      i += 1
    end

    self
  end

  # Runtime method to support case when *foo syntax
  def __matches_when__(receiver)
    each { |x| return true if x === receiver }
    false
  end

  # Creates a new Array from the return values of passing
  # each element in self to the supplied block.
  def map
    return dup unless block_given?
    array = Array.new size
    i = -1
    each { |x| array[i+=1] = yield(x) }
    array
  end

  # Replaces each element in self with the return value
  # of passing that element to the supplied block.
  def map!
    Ruby.check_frozen

    return to_enum(:map!) unless block_given?

    i = -1
    each { |x| self[i+=1] = yield(x) }

    self
  end

  def to_tuple
    tuple = Rubinius::Tuple.new @total
    tuple.copy_from @tuple, @start, @total, 0
    tuple
  end
end
