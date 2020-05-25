def try_all_sort(s)
  s.permutation(s.size){ |x|
    return x if x.each_cons(2).all?{ |a,b| a<=b }
  }
end
# 012 ABCD 1|l 0O
# 日本語 𩹉 🐶