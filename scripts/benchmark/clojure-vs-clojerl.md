## Clojure JVM
- VM:  1.8.0_192
- Clojure:  1.10.0

## Clojure BEAM
- VM:  Erlang/OTP 19 [erts-8.3.5.4]
- Clojure:  0.4.1-1760.b5be28e

## Comparison

|                                                                                              :clj |                                                                                             :clje |   :runs | :time-clj | :time-clje | :ratio |
|---------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------|---------|-----------|------------|--------|
|                                                                              [], (list 1 2 3 4 5) |                                                                              [], (list 1 2 3 4 5) | 1000000 |       146 |         29 |   0.20 |
|                                                          [coll (int-array [1 2 3])], (nth coll 2) |                                                                [coll (tuple 1 2 3)], (nth coll 2) | 1000000 |       108 |         43 |   0.40 |
|                                                                                  [], (list 1 2 3) |                                                                                  [], (list 1 2 3) | 1000000 |        51 |         33 |   0.65 |
|                                                                               [x 1], (identity x) |                                                                               [x 1], (identity x) | 1000000 |        12 |         11 |   0.92 |
|                                                          [f int-array], (f [1 2 3 4 5 6 7 8 9 0]) |                                                                [f tuple], (f 1 2 3 4 5 6 7 8 9 0) |  100000 |        19 |         19 |   1.00 |
|                                                [coll [1 2 3]], (instance? clojure.lang.ISeq coll) |                                                    [coll [1 2 3]], (satisfies? clojerl.ISeq coll) | 1000000 |        44 |         50 |   1.14 |
|                                                            [coll (int-array [1 2 3])], (seq coll) |                                                                  [coll (tuple 1 2 3)], (seq coll) | 1000000 |        42 |         48 |   1.14 |
|                                       [f (fn [a b c d e f g h i j & more])], (apply f (range 32)) |                                       [f (fn [a b c d e f g h i j & more])], (apply f (range 32)) | 1000000 |       348 |        400 |   1.15 |
|                                                          [coll (int-array [1 2 3])], (first coll) |                                                                [coll (tuple 1 2 3)], (first coll) | 1000000 |        73 |         87 |   1.19 |
|                                      [coll (reduce conj [] (range 40000))], (assoc coll 123 :foo) |                                      [coll (reduce conj [] (range 40000))], (assoc coll 123 :foo) |  100000 |        33 |         41 |   1.24 |
|                                                                 [xs [1 2 3 4 5]], (apply list xs) |                                                                 [xs [1 2 3 4 5]], (apply list xs) | 1000000 |       214 |        275 |   1.29 |
|                                    [coll (reduce conj [] (range (+ 32768 32)))], (conj coll :foo) |                                    [coll (reduce conj [] (range (+ 32768 32)))], (conj coll :foo) |  100000 |        16 |         24 |   1.50 |
|                                                       [f (fn [a b & more])], (apply f (range 32)) |                                                       [f (fn [a b & more])], (apply f (range 32)) | 1000000 |       257 |        390 |   1.52 |
|                                          [coll (reduce conj [] (range (+ 32768 33)))], (pop coll) |                                          [coll (reduce conj [] (range (+ 32768 33)))], (pop coll) |  100000 |        14 |         22 |   1.57 |
|                                                                                        [], (list) |                                                                                        [], (list) | 1000000 |        19 |         34 |   1.79 |
|                                                            [xs (list 1 2 3 4 5)], (apply list xs) |                                                            [xs (list 1 2 3 4 5)], (apply list xs) | 1000000 |       122 |        221 |   1.81 |
|                                                                 [coll (seq [1 2 3])], (next coll) |                                                                 [coll (seq [1 2 3])], (next coll) | 1000000 |        17 |         35 |   2.06 |
|                                                                       [], (= 1 1 1 1 1 1 1 1 1 0) |                                                                       [], (= 1 1 1 1 1 1 1 1 1 0) |  100000 |        46 |         96 |   2.09 |
|                                                                 [coll (seq [1 2 3])], (rest coll) |                                                                 [coll (seq [1 2 3])], (rest coll) | 1000000 |        14 |         33 |   2.36 |
|                                                                     [r (range 1000000)], (last r) |                                                                     [r (range 1000000)], (last r) |       1 |        73 |        175 |   2.40 |
|                                                             [s "{:foo [1 2 3]}"], (read-string s) |                                                             [s "{:foo [1 2 3]}"], (read-string s) |    1000 |        10 |         25 |   2.50 |
|                                                                     [coll [1 2 3]], (conj coll 4) |                                                                     [coll [1 2 3]], (conj coll 4) | 1000000 |        53 |        135 |   2.55 |
|                                                                                       [], (str 1) |                                                                                       [], (str 1) | 1000000 |        15 |         43 |   2.87 |
|                                                                          [], (symbol (quote foo)) |                                                                          [], (symbol (quote foo)) | 1000000 |        10 |         29 |   2.90 |
|                                                                [coll (seq [1 2 3])], (first coll) |                                                                [coll (seq [1 2 3])], (first coll) | 1000000 |        11 |         33 |   3.00 |
|                                                               [f vector], (f 1 2 3 4 5 6 7 8 9 0) |                                                               [f vector], (f 1 2 3 4 5 6 7 8 9 0) |  100000 |        26 |         78 |   3.00 |
|                                                                        [coll [1 2 3]], (seq coll) |                                                                        [coll [1 2 3]], (seq coll) | 1000000 |        26 |         81 |   3.12 |
|                                                  [coll (into [] (range 1000000))], (apply + coll) |                                                  [coll (into [] (range 1000000))], (apply + coll) |       1 |        17 |         53 |   3.12 |
|                                                                                     [], (str nil) |                                                                                     [], (str nil) | 1000000 |         4 |         13 |   3.25 |
|                                      [m {:a 1, :b 2, :c 3}], (zipmap (keys m) (map inc (vals m))) |                                      [m {:c 3, :b 2, :a 1}], (zipmap (keys m) (map inc (vals m))) |  100000 |        88 |        301 |   3.42 |
|                                                                                            [], [] |                                                                                            [], [] | 1000000 |         2 |          7 |   3.50 |
|                                                [xs (range 512)], (last (for [x xs y xs] (+ x y))) |                                                [xs (range 512)], (last (for [x xs y xs] (+ x y))) |       1 |        37 |        135 |   3.65 |
|                                           [coll (take 100000 (iterate inc 0))], (reduce + 0 coll) |                                           [coll (take 100000 (iterate inc 0))], (reduce + 0 coll) |       1 |        18 |         69 |   3.83 |
|                                                                [], (reduce conj [] (range 40000)) |                                                                [], (reduce conj [] (range 40000)) |      10 |        29 |        114 |   3.93 |
|                                                                     [coll "foobar"], (first coll) |                                                                     [coll "foobar"], (first coll) | 1000000 |        72 |        287 |   3.99 |
|                     [[a b c] (take 3 (repeatedly (fn* [] (rand-int 10))))], (count (vec [a b c])) |                     [[a b c] (take 3 (repeatedly (fn* [] (rand-int 10))))], (count (vec [a b c])) | 1000000 |        79 |        317 |   4.01 |
|   [coll (new Foo 1 2)], (loop [i 0 m coll] (if (< i 1000000) (recur (inc i) (assoc m :bar 2)) m)) |   [coll (new Foo 1 2)], (loop [i 0 m coll] (if (< i 1000000) (recur (inc i) (assoc m :bar 2)) m)) |       1 |        38 |        158 |   4.16 |
|                                                         [coll (new Foo 1 2)], (assoc coll :bar 2) |                                                         [coll (new Foo 1 2)], (assoc coll :bar 2) | 1000000 |        39 |        164 |   4.21 |
|                                                                       [coll "foobar"], (seq coll) |                                                                       [coll "foobar"], (seq coll) | 1000000 |        57 |        252 |   4.42 |
|                                                [coll {:foo 1} ks [:foo]], (update-in coll ks inc) |                                                [coll {:foo 1} ks [:foo]], (update-in coll ks inc) | 1000000 |       165 |        734 |   4.45 |
|                                                                                   [r r], (last r) |                                                                                   [r r], (last r) |       1 |        94 |        419 |   4.46 |
|                                          [xs (vec (range 512))], (last (for [x xs y xs] (+ x y))) |                                          [xs (vec (range 512))], (last (for [x xs y xs] (+ x y))) |       4 |       111 |        506 |   4.56 |
| [coll {:foo 1, :bar 2}], (loop [i 0 m coll] (if (< i 100000) (recur (inc i) (assoc m :foo 2)) m)) | [coll {:foo 1, :bar 2}], (loop [i 0 m coll] (if (< i 100000) (recur (inc i) (assoc m :foo 2)) m)) |       1 |         4 |         19 |   4.75 |
|                                                                                     [], (str "1") |                                                                                     [], (str "1") | 1000000 |         4 |         19 |   4.75 |
|                                         [coll []], (instance? clojure.lang.PersistentVector coll) |                                                        [coll []], (instance? clojerl.Vector coll) | 1000000 |         5 |         24 |   4.80 |
|                                                        [s "a" f clojure.string/capitalize], (f s) |                                                        [s "a" f clojure.string/capitalize], (f s) | 1000000 |        69 |        345 |   5.00 |
|                                                                                 [], (str "1" "2") |                                                                                 [], (str "1" "2") | 1000000 |        60 |        312 |   5.20 |
|                                                                             [], (str "1" "2" "3") |                                                                             [], (str "1" "2" "3") | 1000000 |        77 |        425 |   5.52 |
|                                                                 [coll (list 1 2 3)], (first coll) |                                                                 [coll (list 1 2 3)], (first coll) | 1000000 |         8 |         45 |   5.63 |
|                                [a (into [] (range 1000000)) b (into [] (range 1000000))], (= a b) |                                [a (into [] (range 1000000)) b (into [] (range 1000000))], (= a b) |       1 |        26 |        148 |   5.69 |
|                                                                 [s big-str-data], (read-string s) |                                                                 [s big-str-data], (read-string s) |    1000 |       267 |       1610 |   6.03 |
|                                                         [coll (new Foo 1 2)], (assoc coll :baz 3) |                                                         [coll (new Foo 1 2)], (assoc coll :baz 3) | 1000000 |        41 |        265 |   6.46 |
|                                                           [], (doall (take 1000 (cycle [1 2 3]))) |                                                           [], (doall (take 1000 (cycle [1 2 3]))) |    1000 |        74 |        488 |   6.59 |
|                                                                     [coll "foobar"], (nth coll 2) |                                                                     [coll "foobar"], (nth coll 2) | 1000000 |        25 |        167 |   6.68 |
|                                                   [s "aBcDeF" f clojure.string/capitalize], (f s) |                                                   [s "aBcDeF" f clojure.string/capitalize], (f s) | 1000000 |       191 |       1311 |   6.86 |
|                                                           [], (doall (take 1000 (iterate inc 0))) |                                                           [], (doall (take 1000 (iterate inc 0))) |    1000 |        73 |        527 |   7.22 |
|                                                            [coll (range 500000)], (reduce + coll) |                                                            [coll (range 500000)], (reduce + coll) |       1 |         9 |         66 |   7.33 |
|                                                          [], (reduce + (take 64 (cycle [1 2 3]))) |                                                          [], (reduce + (take 64 (cycle [1 2 3]))) |   10000 |        53 |        395 |   7.45 |
|                           [[a b c] (take 3 (repeatedly (fn* [] (rand-int 10))))], (count [a b c]) |                           [[a b c] (take 3 (repeatedly (fn* [] (rand-int 10))))], (count [a b c]) | 1000000 |        25 |        194 |   7.76 |
|                    [[a b c] (take 3 (repeatedly (fn* [] (rand-int 10))))], (count (vector a b c)) |                    [[a b c] (take 3 (repeatedly (fn* [] (rand-int 10))))], (count (vector a b c)) | 1000000 |        25 |        194 |   7.76 |
|                                                                [], (doall (take 1000 (repeat 1))) |                                                                [], (doall (take 1000 (repeat 1))) |    1000 |        47 |        376 |   8.00 |
|                                                                       [], (doall (repeat 1000 1)) |                                                                       [], (doall (repeat 1000 1)) |    1000 |        14 |        112 |   8.00 |
|                                                            [], (reduce + (take 64 (repeat 48 1))) |                                                            [], (reduce + (take 64 (repeat 48 1))) |   10000 |        30 |        251 |   8.37 |
|                                                          [], (reduce + (take 64 (iterate inc 0))) |                                                          [], (reduce + (take 64 (iterate inc 0))) |   10000 |        47 |        405 |   8.62 |
|                                                               [], (reduce + (take 64 (repeat 1))) |                                                               [], (reduce + (take 64 (repeat 1))) |   10000 |        35 |        318 |   9.09 |
|                                               [coll (into [] (range 1000000))], (reduce + 0 coll) |                                               [coll (into [] (range 1000000))], (reduce + 0 coll) |       1 |        14 |        131 |   9.36 |
|                               [xs (range 1000000)], (reduce + 0 (map inc (map inc (map inc xs)))) |                               [xs (range 1000000)], (reduce + 0 (map inc (map inc (map inc xs)))) |       1 |        87 |        827 |   9.51 |
|                                           [coll (list 1 2 3)], (instance? clojure.lang.ISeq coll) |                                               [coll (list 1 2 3)], (satisfies? clojerl.ISeq coll) | 1000000 |         5 |         48 |   9.60 |
|                                                                      [coll [1 2 3]], (nth coll 0) |                                                                      [coll [1 2 3]], (nth coll 0) | 1000000 |         8 |         80 |  10.00 |
|           [xs (into [] (range 1000000))], (transduce (comp (map inc) (map inc) (map inc)) + 0 xs) |           [xs (into [] (range 1000000))], (transduce (comp (map inc) (map inc) (map inc)) + 0 xs) |       1 |        59 |        598 |  10.14 |
|                                                                                   [r r], (last r) |                                                                                   [r r], (last r) |       1 |        40 |        409 |  10.22 |
|                                                                  [coll (list 1 2 3)], (rest coll) |                                                                  [coll (list 1 2 3)], (rest coll) | 1000000 |         7 |         72 |  10.29 |
|                [v (into [] (range 1000000))], (loop [[x & xs] v] (if-not (nil? xs) (recur xs) x)) |                [v (into [] (range 1000000))], (loop [[x & xs] v] (if-not (nil? xs) (recur xs) x)) |      10 |       177 |       1856 |  10.49 |
|                                                         [coll (range 1000000)], (reduce + 0 coll) |                                                         [coll (range 1000000)], (reduce + 0 coll) |       1 |        12 |        132 |  11.00 |
|                                                                  [], (reduce + 0 (repeat 1000 1)) |                                                                  [], (reduce + 0 (repeat 1000 1)) |    1000 |        11 |        126 |  11.45 |
|                                                       [], (transduce (take 64) + (cycle [1 2 3])) |                                                       [], (transduce (take 64) + (cycle [1 2 3])) |   10000 |        27 |        326 |  12.07 |
|                                                                              [x true], (pr-str x) |                                                                              [x true], (pr-str x) |    1000 |         1 |         13 |  13.00 |
|                                                                          [coll [1 2 3]], (coll 0) |                                                                          [coll [1 2 3]], (coll 0) | 1000000 |         5 |         69 |  13.80 |
|                                                         [], (into [] (take 1000) (cycle [1 2 3])) |                                                         [], (into [] (take 1000) (cycle [1 2 3])) |    1000 |        47 |        663 |  14.11 |
|                                                                                [x 10], (pr-str x) |                                                                                [x 10], (pr-str x) |    1000 |         1 |         15 |  15.00 |
|                                                                     [], (into [] (repeat 1000 1)) |                                                                     [], (into [] (repeat 1000 1)) |    1000 |        16 |        252 |  15.75 |
|                                                              [coll {:foo 1, :bar 2}], (:foo coll) |                                                              [coll {:foo 1, :bar 2}], (:foo coll) | 1000000 |         9 |        150 |  16.67 |
|                                                              [], (into [] (take 1000) (repeat 1)) |                                                              [], (into [] (take 1000) (repeat 1)) |    1000 |        34 |        593 |  17.44 |
|                                                          [coll {:foo 1, :bar 2}], (get coll :foo) |                                                          [coll {:foo 1, :bar 2}], (get coll :foo) | 1000000 |         7 |        123 |  17.57 |
|                                                              [], (into [] (take 1000) (repeat 1)) |                                                              [], (into [] (take 1000) (repeat 1)) |    1000 |        34 |        600 |  17.65 |
|                                                         [], (into [] (take 1000) (iterate inc 0)) |                                                         [], (into [] (take 1000) (iterate inc 0)) |    1000 |        39 |        695 |  17.82 |
|                                                                [coll {:foo 1, :bar 2}], (kw coll) |                                                                [coll {:foo 1, :bar 2}], (kw coll) | 1000000 |         8 |        151 |  18.88 |
|                                                         [], (transduce (take 64) + (repeat 48 1)) |                                                         [], (transduce (take 64) + (repeat 48 1)) |   10000 |        11 |        223 |  20.27 |
|                                                 [coll {(quote foo) 1, (quote bar) 2}], (sym coll) |                                                 [coll {(quote foo) 1, (quote bar) 2}], (sym coll) | 1000000 |        10 |        204 |  20.40 |
|                                     [coll {(quote foo) 1, (quote bar) 2}], (get coll (quote foo)) |                                     [coll {(quote foo) 1, (quote bar) 2}], (get coll (quote foo)) | 1000000 |         9 |        184 |  20.44 |
|                                         [coll {(quote foo) 1, (quote bar) 2}], ((quote foo) coll) |                                         [coll {(quote foo) 1, (quote bar) 2}], ((quote foo) coll) | 1000000 |        10 |        207 |  20.70 |
|                                                            [], (transduce (take 64) + (repeat 1)) |                                                            [], (transduce (take 64) + (repeat 1)) |   10000 |        14 |        296 |  21.14 |
|                                                                 [coll (new Foo 1 2)], (:bar coll) |                                                                 [coll (new Foo 1 2)], (:bar coll) | 1000000 |         6 |        129 |  21.50 |
|                                                       [], (transduce (take 64) + (iterate inc 0)) |                                                       [], (transduce (take 64) + (iterate inc 0)) |   10000 |        16 |        345 |  21.56 |
|                     [xs (range 1000000)], (transduce (comp (map inc) (map inc) (map inc)) + 0 xs) |                     [xs (range 1000000)], (transduce (comp (map inc) (map inc) (map inc)) + 0 xs) |       1 |        22 |        600 |  27.27 |
|                                                                           [], (simple-multi :foo) |                                                                           [], (simple-multi :foo) | 1000000 |        21 |        744 |  35.43 |