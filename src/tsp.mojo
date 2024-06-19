from python import Python
from matrixtype import Matrix
from random import randint
from random import random_float64
from time import now

alias crossover_probability: Float64 = 0.8
alias mutation_probability: Float64 = 0.2


fn load_distances() raises -> List[Int]:
    var mod = Python.import_module("urllib.request")
    var json = Python.import_module("json")
    var f = mod.urlopen("https://pastebin.com/raw/9s0GBakS")
    var data = f.read().decode("utf-8")
    var lista_numeros = json.loads(data)
    var vector = List[Int]()
    for item in lista_numeros:
        vector.append(int(item))
    print("Total distances: ", len(vector))
    return vector


fn load_cities(city_count: Int) raises -> Matrix[DType.float32]:
    var cities = Matrix[DType.float32](int(city_count), int(city_count))
    var distances = load_distances()
    for y in range(city_count):
        for x in range(city_count):
            cities.store[nelts=1](y, x, distances[y * city_count + x])
    return cities


fn generate_permutation(city_count: Int) -> DTypePointer[DType.int32]:
    # Genera una ruta aleatoria que visita cada ciudad exactamente una vez
    # var np = Python.import_module("numpy")
    # route = np.random.permutation(int(city_count))
    var vector = DTypePointer[DType.int32].alloc(city_count)
    for i in range(city_count):
        vector[i] = i

    # Algoritmo de Fisher-Yates para mezclar la lista
    for i in range(city_count - 1, 0, -1):
        var j = int(random_float64() * (i + 1))
        # Intercambiar elementos
        var temp = vector[i]
        vector[i] = vector[j]
        vector[j] = temp
    return vector


fn calculate_distance(
    pos_city1: Int, pos_city2: Int, inout cities: Matrix[DType.float32]
) -> Float32:
    # Función para calcular la distancia entre dos ciudades (puede ser la distancia euclidiana)
    # var position = pos_city2 * cities.size + pos_city1
    return cities.load[nelts=1](pos_city1, pos_city2)


fn calculate_distance_lineal(
    pos_city1: Int, post_city2: Int, cities: Matrix[DType.float32]
) -> Float32:
    # Función para calcular la distancia entre dos ciudades (puede ser la distancia euclidiana)
    # var position = post_city2 * cities.size + pos_city1
    var xA = cities.__getitem__(pos_city1, 0)
    var yA = cities.__getitem__(pos_city1, 1)
    var xB = cities.__getitem__(post_city2, 0)
    var yB = cities.__getitem__(post_city2, 1)
    var xdiff = xA - xB
    var ydiff = yA - yB
    var distance = ((xdiff) ** 2 + (ydiff) ** 2) ** 0.5
    return distance


fn total_distance(
    inout population: Matrix[DType.int32],
    pop_idx: Int,
    inout cities: Matrix[DType.float32],
    city_count: Int,
) -> SIMD[DType.float32, 1]:
    # Función para calcular la distancia total de un recorrido (ruta)
    var distance: Float32 = 0.0
    # print_no_newline("Population: ")
    # print_no_newline(pop_id)
    for city_idx in range(city_count - 1):
        var pos_city1: Int = int(population.__getitem__(pop_idx, city_idx))
        var pos_city2: Int = int(population.__getitem__(pop_idx, city_idx + 1))
        var new_distance = calculate_distance(pos_city1, pos_city2, cities)
        distance += new_distance
    # distance += calculate_distance(route[-1], route[0])  # Volver al inicio
    # print_no_newline(" Distancia: ")
    # print(distance)
    return distance


fn evaluate_population(
    inout population: Matrix[DType.int32],
    inout cities: Matrix[DType.float32],
    city_count: Int,
    population_size: Int,
) -> List[SIMD[DType.float32, 1]]:
    # Evalúa la aptitud de cada individuo en la población
    var fitness_values = List[SIMD[DType.float32, 1]]()
    for y in range(population_size):
        fitness_values.append(total_distance(population, y, cities, city_count))
    return fitness_values


fn containInArray(array: List[Int], value: Int) -> Bool:
    for i in range(array.size):
        if array[i] == value:
            return True
    return False


fn printVector(vector: List[Int]):
    for i in range(vector.size):
        if i > 0:
            print(", ", end="")
        print(vector[i], end="")
    print("")


fn crossover(
    parentId1: Int, parentId2: Int, inout population: Matrix[DType.int32]
) -> Int:
    # Implementa el operador de cruce (crossover) para generar dos descendientes a partir de dos padres
    var crossover_point: Int = int(random_float64() * (population.cols - 1))
    var parent1_left = List[Int]()
    var parent2_left = List[Int]()

    var parent1_right = List[Int]()
    var parent2_right = List[Int]()

    # print("Crossover point: ", crossover_point)

    for i in range(crossover_point):
        parent1_left.append(int(population.__getitem__(parentId1, i)))
        parent2_left.append(int(population.__getitem__(parentId2, i)))

    # print("Parent1 Left: ")
    # printVector(parent1_left)
    # print("Parent2 Left: ")
    # printVector(parent2_left)

    # extract the values that are not in the parents
    for i in range(population.cols):
        if not containInArray(
            parent1_left, int(population.__getitem__(parentId2, i))
        ):
            parent1_right.append(int(population.__getitem__(parentId2, i)))

        if not containInArray(
            parent2_left, int(population.__getitem__(parentId1, i))
        ):
            parent2_right.append(int(population.__getitem__(parentId1, i)))

    # fill parents with the rest of the values
    # print("Parent2 Right: ")
    # printVector(parent1_right)
    # print("Parent2 Right: ")
    # printVector(parent2_right)
    # print("Parent1 Right size: ", parent1_right.size)

    # obtiene una posicion libre en la poblacion
    var new_children1_id = population.not_selected.pop()
    # print("New children1 id: ", new_children1_id)

    for i in range(parent1_left.size):
        population.__setitem__(new_children1_id, i, parent1_left[i])

    for i in range(parent1_right.size):
        population.__setitem__(
            new_children1_id, crossover_point + i, parent1_right[i]
        )

    return new_children1_id


fn mutate(inout population: Matrix[DType.int32], populationId: Int):
    # Implementa el operador de mutación para perturbar la ruta de manera aleatoria
    var mutation_points = generate_permutation(population.cols)
    # print("Mutation points: ", mutation_points[0], " ", mutation_points[1])
    var temp = population.__getitem__(populationId, int(mutation_points[0]))
    population.__setitem__(
        populationId,
        int(mutation_points[0]),
        population.__getitem__(populationId, int(mutation_points[1])),
    )
    population.__setitem__(populationId, int(mutation_points[1]), temp)


fn getIndexSorted(values: List[SIMD[DType.float32, 1]]) -> List[Int]:
    var indices = List[Int]()
    for i in range(values.size):
        indices.append(i)

    # print("Sort Fitness Values")
    # Algoritmo de selección para ordenar los índices
    for i in range(values.size - 1):
        var minIndex: Int = i
        for j in range(i + 1, values.size, 1):
            if values[indices[j]] < values[indices[minIndex]]:
                minIndex = j

        # Intercambiar los índices
        var temp = indices[i]
        indices[i] = indices[minIndex]
        indices[minIndex] = temp

    return indices


fn evolve_population(inout population: Matrix[DType.int32]):
    # Evoluciona la población aplicando operadores genéticos

    # Selección basada en torneo
    var new_child = List[Int]()
    var not_selected = List[Int]()
    not_selected.__copyinit__(population.not_selected)

    for _ in range(population.selected.size):
        var tournament_indices = generate_permutation(population.selected.size)
        var parent1 = int(tournament_indices[0])
        var parent2 = int(tournament_indices[1])

        # Aplicar cruce con una cierta probabilidad
        if random_float64() < crossover_probability:
            var new_id = crossover(
                population.selected[parent1],
                population.selected[parent2],
                population,
            )
            new_child.append(new_id)

    # Aplicar mutación con una cierta probabilidad
    for i in range(not_selected.size):
        if random_float64() < mutation_probability:
            mutate(population, not_selected[i])


fn select_elite(
    inout population: Matrix[DType.int32],
    fitness_values: List[SIMD[DType.float32, 1]],
    population_size: Int,
) raises:
    # Selecciona los mejores individuos de la población
    var index_sorted = getIndexSorted(fitness_values)
    population.selected.clear()
    for i in range(population_size / 2):
        population.selected.append(index_sorted[i])
    population.not_selected = population.findNotSelected()
    # print("Selected: ", population.selected.size)
    # printVector(population.selected)
    # print("Not Selected: ", population.not_selected.size)
    # printVector(population.not_selected)


fn main() raises:
    print("Hello Mojo 🔥!")
    # Parámetros del algoritmo genético
    var city_count: Int = 251
    var population_size: Int = 100
    var generations: Int = 1000
    var start_time = now()

    # Generar ciudades aleatorias en un espacio bidimensional
    print("Cities:")
    var cities: Matrix[DType.float32] = load_cities(city_count)
    cities.dump()

    # Inicializar la población
    var population = Matrix[DType.int32](population_size, city_count)
    for i in range(population_size):
        population.__setline__(i, city_count, generate_permutation(city_count))

    # print("Poblacion:")
    # population.dump()

    for i in range(generations):
        var fitness_values: List[SIMD[DType.float32, 1]] = evaluate_population(
            population, cities, city_count, population_size
        )

        select_elite(population, fitness_values, population_size)
        print(
            "Generacion: ",
            i,
            "Best route: ",
            population.selected[0],
            " Distance: ",
            fitness_values[population.selected[0]],
        )

        evolve_population(population)

    print("Best Route:")
    population.dump_line(population.selected[0])

    print("execution time", (now() - start_time) / 1000000000)

    # print("Poblacion:")
    # population.dump()
    # print("End")
