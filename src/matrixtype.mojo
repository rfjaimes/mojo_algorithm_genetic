from random import rand


struct Matrix[type: DType]:
    var data: DTypePointer[type]
    var rows: Int
    var cols: Int
    var size: Int
    var selected: List[Int]
    var not_selected: List[Int]

    fn __init__(inout self, rows: Int, cols: Int):
        self.data = DTypePointer[type].alloc(rows * cols)
        rand(self.data, rows * cols)
        self.rows = rows
        self.cols = cols
        self.size = rows
        self.selected = List[Int]()
        self.not_selected = List[Int]()

    fn __copyinit__(inout self, other: Self):
        self.data = other.data
        self.rows = other.rows
        self.cols = other.cols
        self.size = other.size
        self.selected = other.selected
        self.not_selected = other.not_selected

    fn zero(inout self):
        memset_zero(self.data, self.rows * self.cols)

    @always_inline
    fn __getitem__(self, y: Int, x: Int) -> SIMD[type, 1]:
        return self.load[1](y, x)

    @always_inline
    fn load[nelts: Int](self, y: Int, x: Int) -> SIMD[type, nelts]:
        if y * self.cols + x > self.rows * self.cols:
            print("overflow position: ", y * self.cols + x)
        return self.data.load[width=nelts](y * self.cols + x)

    @always_inline
    fn __setitem__(self, y: Int, x: Int, val: SIMD[type, 1]):
        return self.store[1](y, x, val)

    @always_inline
    fn __setline__(self, y: Int, size: Int, values: DTypePointer[type]):
        for i in range(size):
            self.data.store[width=1](y * self.cols + i, values.load[width=1](i))

    @always_inline
    fn store[nelts: Int](self, y: Int, x: Int, val: SIMD[type, nelts]):
        self.data.store[width=nelts](y * self.cols + x, val)

    @always_inline
    def containInArray(self, array: List[Int], value: Int) -> Bool:
        for i in range(array.size):
            if array[i] == value:
                return True
        return False

    @always_inline
    fn findNotSelected(self) raises -> List[Int]:
        var not_selected = List[Int]()
        for i in range(self.size):
            if not self.containInArray(self.selected, i):
                not_selected.append(i)
        return not_selected

    fn dump_line(self, y: Int):
        print("[", end="")
        for x in range(self.cols):
            if x > 0:
                print(", ", end="")
            print(self.load[1](y, x), end="")
        print("],")

    fn dump(self):
        print("[")
        for y in range(self.rows):
            self.dump_line(y)
        print("]")

    fn dump_selected(self):
        print("[")
        for y in range(self.selected.size):
            self.dump_line(self.selected[y])
        print("]")
