let a = [1, 2, 3]
let b = [4, 5, 6]

let z = Zip2(a, b)
let s = reduce(z, 0) {$0.0 + $1.0 * $1.1}
println(s)
