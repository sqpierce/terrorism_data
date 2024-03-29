require 'set'

class Array

# Performs delete_if and returns the elements deleted instead (delete_if will return the array with elements removed).
# Because it is essentially delete_if, this method is destructive. Also this method is kinda redundant as you can simply
# call dup.delete_if passing it the negation of the condition.

def delete_fi
  x = select { |v| v if yield(v) }
  delete_if { |v| v if yield(v) }
  x.empty? ? nil : x
end

# Turns array into a queue. Shifts proceeding n elements forward
# and moves the first n elements to the back. When called with
# a block, performs next! and returns the result of block
# performed on that new first element. This method is destructive.

# a = [1,2,3].next!  => [2,3,1]
# a.next! { |x| x+ 10 } => 13
# a is now [3,1,2]

def next!(n=1)
  n.times do
    push(shift)
  end
  if block_given?
    y = yield(first)
    y
  else
    self
  end
end

# Treats [x,y] as a range and expands it to an array with y elements
# from x to y.

# [1,10].expand => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
# [1,10].expand { |x| x**2 } => [1, 4, 9, 16, 25, 36, 49, 64, 81, 100]

def expand
  x = (first..last).to_a
  if block_given?
    x.collect { |x| yield(x) }
  else
    x
  end
end

def shuffle!
   each_index do |i|
     j = rand(length-i) + i
     self[j], self[i] = self[i], self[j]
   end
end

def pick(n=1)
  y = Set.new
  until y.size == n
    t = self[rand(size)]
    y.add(t)
  end
  y.to_a
  y.to_a.first if n == 1
end

# ======== MATRIX CRUD ========= #

# Turns [x,y] into a matrix with x rows and y columns and fills them
# with the result of block. Block must be given *without* arguments.
# If no block is given, the method yields a sparse matrix.

# m = [3,3].to_matrix { rand(30) }
# => [[20, 26, 5, 14, 10], [20, 0, 28, 21, 18], [21, 16, 20, 12, 11]]

def to_matrix
  row = first
  col = last
  if block_given?
    x = Array.new(row) { Array.new(col) { yield } }
  else
    x = Array.new(row) { Array.new(col,0) }
  end
  x
end

def each_coordinate
  each_with_index do |row,x|
    row.each_with_index do |col,y|
      yield(x,y)
    end
  end
end

def mx_lookup(row,col)
  if row < 0 || col < 0
    nil
  else
    self[row][col]
  end
end

def mx_assign(row,col,val)
  self[row][col] = val
end

def mx_update(row,col,new_val)
  self[row][col] = new_val
end

end

class Hash

# Performs delete_if and returns the elements deleted. Because
# it is essentially delete_if, this method is destructive.

def delete_fi
  x = select { |k,v| yield(k,v) }
  delete_if { |k,v| yield(k,v) }
  x.empty? ? nil : x
end

def collect
  x = select { |k,v| yield(k,v) }
  h = x.inject({}) { |h,v| h.update x.first => x.last }
  h
end

end

class Range
  
# Returns an array with n random numbers within range.
  
	def pick(n=1)
    y = []
	  x = [first,last].expand
	  n.times { y << x[rand(x.size)] }
    y
    y.first if n == 1
	end
	
end
