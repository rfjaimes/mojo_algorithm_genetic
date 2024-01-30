from python import Python
from matrixtype import Matrix
from random import randint
from random import random_float64
from algorithm.sort import sort
from time import now

alias crossover_probability: Float64 = 0.8
alias mutation_probability: Float64 = 0.2


fn load_distances() raises -> DynamicVector[Int]:
    var mod = Python.import_module("urllib.request")
    var json = Python.import_module("json")
    var f = mod.urlopen("https://pastebin.com/raw/9s0GBakS")
    var data = f.read().decode("utf-8")
    var lista_numeros = json.loads(data)
    var vector = DynamicVector[Int]()
    for item in lista_numeros:
        vector.append(int(item))
    print("Total distances: ", len(vector))
    return vector


fn load_cities(city_count: Int) raises -> Matrix[DType.float32]:
    # let np = Python.import_module("numpy")
    var cities = Matrix[DType.float32](int(city_count), 2)
    cities.selected = load_distances()
    return cities


fn generate_permutation(city_count: Int) -> DTypePointer[DType.int32]:
    # Genera una ruta aleatoria que visita cada ciudad exactamente una vez
    # let np = Python.import_module("numpy")
    # route = np.random.permutation(int(city_count))
    let vector = DTypePointer[DType.int32].alloc(city_count)
    for i in range(city_count):
        vector[i] = i

    # Algoritmo de Fisher-Yates para mezclar la lista
    for i in range(city_count - 1, 0, -1):
        let j = (random_float64() * (i + 1)).to_int()
        # Intercambiar elementos
        let temp = vector[i]
        vector[i] = vector[j]
        vector[j] = temp
    return vector


fn calculate_distance(
    pos_city1: Int, post_city2: Int, inout cities: Matrix[DType.float32]
) -> Float32:
    # Función para calcular la distancia entre dos ciudades (puede ser la distancia euclidiana)
    let position = post_city2 * 251 + pos_city1
    return cities.selected[position]


fn calculate_distance_lineal(
    pos_city1: Int, post_city2: Int, cities: Matrix[DType.float32]
) -> Float32:
    # Función para calcular la distancia entre dos ciudades (puede ser la distancia euclidiana)
    # let position = post_city2 * 251 + pos_city1
    let xA = cities.__getitem__(pos_city1, 0)
    let yA = cities.__getitem__(pos_city1, 1)
    let xB = cities.__getitem__(post_city2, 0)
    let yB = cities.__getitem__(post_city2, 1)
    let xdiff = xA - xB
    let ydiff = yA - yB
    let distance = ((xdiff) ** 2 + (ydiff) ** 2) ** 0.5
    return distance


fn total_distance(
    inout population: Matrix[DType.int32],
    y: Int,
    inout cities: Matrix[DType.float32],
    city_count: Int,
) -> SIMD[DType.float32, 1]:
    # Función para calcular la distancia total de un recorrido (ruta)
    var distance: Float32 = 0.0
    # print_no_newline("Population: ")
    # print_no_newline(y)
    for i in range(city_count - 1):
        let pos_city1: Int = population.__getitem__(y, i).to_int()
        let pos_city2: Int = population.__getitem__(y, i + 1).to_int()
        let new_distance = calculate_distance(pos_city1, pos_city2, cities)
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
) -> DynamicVector[SIMD[DType.float32, 1]]:
    # Evalúa la aptitud de cada individuo en la población
    var fitness_values = DynamicVector[SIMD[DType.float32, 1]]()
    for y in range(population_size):
        fitness_values.append(total_distance(population, y, cities, city_count))
    return fitness_values


fn containInArray(array: DynamicVector[Int], value: Int) -> Bool:
    for i in range(array.size):
        if array[i] == value:
            return True
    return False


fn printVector(vector: DynamicVector[Int]):
    for i in range(vector.size):
        if i > 0:
            print_no_newline(", ")
        print_no_newline(vector[i])
    print("")


fn crossover(
    parentId1: Int, parentId2: Int, inout population: Matrix[DType.int32]
) -> Int:
    # Implementa el operador de cruce (crossover) para generar dos descendientes a partir de dos padres
    var crossover_point: Int = (random_float64() * (population.cols - 1)).to_int()
    var parent1_left = DynamicVector[Int]()
    var parent2_left = DynamicVector[Int]()

    var parent1_right = DynamicVector[Int]()
    var parent2_right = DynamicVector[Int]()

    # print("Crossover point: ", crossover_point)

    for i in range(crossover_point):
        parent1_left.append(population.__getitem__(parentId1, i).to_int())
        parent2_left.append(population.__getitem__(parentId2, i).to_int())

    # print("Parent1 Left: ")
    # printVector(parent1_left)
    # print("Parent2 Left: ")
    # printVector(parent2_left)

    # extract the values that are not in the parents
    for i in range(population.cols):
        if not containInArray(
            parent1_left, population.__getitem__(parentId2, i).to_int()
        ):
            parent1_right.append(population.__getitem__(parentId2, i).to_int())

        if not containInArray(
            parent2_left, population.__getitem__(parentId1, i).to_int()
        ):
            parent2_right.append(population.__getitem__(parentId1, i).to_int())

    # fill parents with the rest of the values
    # print("Parent2 Right: ")
    # printVector(parent1_right)
    # print("Parent2 Right: ")
    # printVector(parent2_right)
    # print("Parent1 Right size: ", parent1_right.size)

    # obtiene una posicion libre en la poblacion
    var new_children1_id = population.not_selected.pop_back()
    # print("New children1 id: ", new_children1_id)

    for i in range(parent1_left.size):
        population.__setitem__(new_children1_id, i, parent1_left[i])

    for i in range(parent1_right.size):
        population.__setitem__(new_children1_id, crossover_point + i, parent1_right[i])

    return new_children1_id


fn mutate(inout population: Matrix[DType.int32], populationId: Int):
    # Implementa el operador de mutación para perturbar la ruta de manera aleatoria
    var mutation_points = generate_permutation(population.cols)
    # print("Mutation points: ", mutation_points[0], " ", mutation_points[1])
    let temp = population.__getitem__(populationId, mutation_points[0].to_int())
    population.__setitem__(
        populationId,
        mutation_points[0].to_int(),
        population.__getitem__(populationId, mutation_points[1].to_int()),
    )
    population.__setitem__(populationId, mutation_points[1].to_int(), temp)


fn getIndexSorted(values: DynamicVector[SIMD[DType.float32, 1]]) -> DynamicVector[Int]:
    var indices = DynamicVector[Int]()
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
        let temp = indices[i]
        indices[i] = indices[minIndex]
        indices[minIndex] = temp

    return indices


fn evolve_population(inout population: Matrix[DType.int32]):
    # Evoluciona la población aplicando operadores genéticos

    # Selección basada en torneo
    var new_child = DynamicVector[Int]()
    var not_selected = DynamicVector[Int]()
    not_selected.__copyinit__(population.not_selected)

    for i in range(population.selected.size):
        let tournament_indices = generate_permutation(population.selected.size)
        let parent1 = tournament_indices[0].to_int()
        let parent2 = tournament_indices[1].to_int()

        # Aplicar cruce con una cierta probabilidad
        if random_float64() < crossover_probability:
            let new_id = crossover(
                population.selected[parent1], population.selected[parent2], population
            )
            new_child.append(new_id)

    # Aplicar mutación con una cierta probabilidad
    for i in range(not_selected.size):
        if random_float64() < mutation_probability:
            mutate(population, not_selected[i])


fn select_elite(
    inout population: Matrix[DType.int32],
    fitness_values: DynamicVector[SIMD[DType.float32, 1]],
    population_size: Int,
) raises:
    # Selecciona los mejores individuos de la población
    let index_sorted = getIndexSorted(fitness_values)
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
    let city_count: Int = 251
    let population_size: Int = 100
    let generations: Int = 2000
    let start_time = now()

    # Generar ciudades aleatorias en un espacio bidimensional
    let distances = load_distances()
    # print("Cities:")
    var cities: Matrix[DType.float32] = load_cities(city_count)
    # cities.dump()

    # Inicializar la población
    var population = Matrix[DType.int32](population_size, city_count)
    for i in range(population_size):
        population.__setline__(i, city_count, generate_permutation(city_count))

    # print("Poblacion:")
    # population.dump()

    for i in range(generations):
        var fitness_values: DynamicVector[SIMD[DType.float32, 1]] = evaluate_population(
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
