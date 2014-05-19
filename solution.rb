#!/usr/bin/ruby

# TODO: optimize the code below, and put into classes for cleanliness

# Tee up the input
lines = $stdin.read.split("\n")
num_balances = lines[0].to_i
balance_info = {}
(0..(lines.size / 2 - 1)).each do |balance_num|
  left_info  = lines[balance_num * 2 + 1].split(' ')
  right_info = lines[balance_num * 2 + 2].split(' ')
  balance_info[balance_num] = {
    wl: left_info[0].to_i,
    wr: right_info[0].to_i,
    bl: left_info[1..-1].map { |n| n.to_i },
    br: right_info[1..-1].map { |n| n.to_i }
  }
end
throw "Something's wrong with our counting" unless balance_info.size == num_balances

# Simple array sum
def sum(arr)
  s = 0
  arr.each do |a|
    s += a
  end
  s
end

# Excessive dup'ing to avoid overwriting
# hash vals accidentally
def dup_bi(hsh)
  neww = {}
  hsh.each do |k, v|
    neww[k] = {}
    v.each do |k1, v1|
      neww[k][k1] = v1
    end
  end
  neww
end

# Compute the weights on all of the thingies
def weight_on_me(balance_num, balance_info_orig)
  balance_info = dup_bi(balance_info_orig)
  {
    wl: balance_info[balance_num][:wl] +
      sum(balance_info[balance_num][:bl].map { |bn| sum(weight_on_me(bn, balance_info).values) }) +
      balance_info[balance_num][:bl].size * 10,
    wr: balance_info[balance_num][:wr] +
      sum(balance_info[balance_num][:br].map { |bn| sum(weight_on_me(bn, balance_info).values) }) +
      balance_info[balance_num][:br].size * 10
  }
end

# How low am I sitting?
def my_depth(balance_num, balance_info_orig)
  balance_info = dup_bi(balance_info_orig)
  ones_im_right_above = balance_info.select { |k, bi| (bi[:bl] + bi[:br]).include?(balance_num) }
  if ones_im_right_above.size > 0
    # Assume consistent, so just return the first
    1 + my_depth(ones_im_right_above.keys.first, balance_info)
  else
    0
  end
end
depths = Hash[balance_info.keys.zip(balance_info.keys.map { |bn| my_depth(bn, balance_info) })]
balances_ordered_by_depth = (0..(num_balances - 1)).to_a.sort_by { |i| -depths[i] }

# Find the highest possible one that isn't balanced
def highest_unbalanced(balance_info, balances_ordered_by_depth)
  balances_ordered_by_depth.each do |balance_num|
    my_weights = weight_on_me(balance_num, balance_info)
    return balance_num unless my_weights[:wl] == my_weights[:wr]
  end
  nil
end

# Combine the weights in balance_info with
# ones we manually add in diff
def add_trees(balance_info, diff)
  neww = dup_bi(balance_info)
  diff.each do |num, wts|
    neww[num][:wr] += wts[:wr] if wts[:wr]
    neww[num][:wl] += wts[:wl] if wts[:wl]
  end
  neww
end

# One by one, figure out the highest unbalanced node,
# add weight to it, and then try again
diff = {}
hu = highest_unbalanced(add_trees(balance_info, diff), balances_ordered_by_depth)
until hu.nil?
  wts = weight_on_me(hu, add_trees(balance_info, diff))
  if wts[:wl] > wts[:wr]
    diff[hu] = {} unless diff[hu]
    diff[hu][:wr] = 0 unless diff[hu][:wr]
    diff[hu][:wr] += (wts[:wl] - wts[:wr])
  elsif wts[:wl] < wts[:wr]
    diff[hu] = {} unless diff[hu]
    diff[hu][:wl] = 0 unless diff[hu][:wl]
    diff[hu][:wl] += (wts[:wr] - wts[:wl])
  end
  hu = highest_unbalanced(add_trees(balance_info, diff), balances_ordered_by_depth)
end

# Output
(0..(num_balances - 1)).each do |idx|
  puts "#{idx}: #{(diff[idx] || {})[:wl] || 0} #{(diff[idx] || {})[:wr] || 0}"
end; nil
