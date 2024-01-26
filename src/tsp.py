import random
import itertools
import multiprocessing
from urllib import request
import json

lista_numeros = []

def load_distances():
    global lista_numeros
    f = request.urlopen('https://pastebin.com/raw/9s0GBakS')
    data = f.read().decode('utf-8')
    lista_numeros = json.loads(data)
    return lista_numeros

def calculate_distance(pos_city1, post_city2):
    # Función para calcular la distancia entre dos ciudades (puede ser la distancia euclidiana)
    # return ((city1[0] - city2[0])**2 + (city1[1] - city2[1])**2)**0.5
    return lista_numeros[post_city2 * 251 + pos_city1]

def total_distance(route, cities):
    # Función para calcular la distancia total de un recorrido (ruta)
    distance = 0
    for i in range(len(route) - 1):
        distance += calculate_distance(route[i], route[i + 1])
    # distance += calculate_distance(route[-1], route[0])  # Volver al inicio
    return distance

def generate_random_route(city_count):
    # Genera una ruta aleatoria que visita cada ciudad exactamente una vez
    return random.sample(range(city_count), city_count)

def evaluate_population(population, cities):
    # Evalúa la aptitud de cada individuo en la población
    fitness_values = []
    for route in population:
        fitness_values.append(total_distance(route, cities))
    return fitness_values

def crossover(parent1, parent2):
    # Implementa el operador de cruce (crossover) para generar dos descendientes a partir de dos padres
    crossover_point = random.randint(1, len(parent1) - 1)
    child1 = parent1[:crossover_point] + [city for city in parent2 if city not in parent1[:crossover_point]]
    child2 = parent2[:crossover_point] + [city for city in parent1 if city not in parent2[:crossover_point]]
    return child1, child2

def mutate(route):
    # Implementa el operador de mutación para perturbar la ruta de manera aleatoria
    mutation_point1, mutation_point2 = random.sample(range(len(route)), 2)
    route[mutation_point1], route[mutation_point2] = route[mutation_point2], route[mutation_point1]
    return route

def evolve_population(subpopulation, cities):
    # Evoluciona la subpoblación aplicando operadores genéticos
    new_population = []
    new_population.extend(subpopulation)

    # Selección basada en torneo
    for _ in range(int(len(subpopulation)/2)):
        tournament_indices = random.sample(range(len(subpopulation)), 2)
        parent1, parent2 = subpopulation[tournament_indices[0]], subpopulation[tournament_indices[1]]

        # Aplicar cruce con una cierta probabilidad
        if random.random() < crossover_probability:
            child1, child2 = crossover(parent1, parent2)
            new_population.extend([child1, child2])

    # Aplicar mutación con una cierta probabilidad
    for i in range(len(new_population)):
        if random.random() < mutation_probability:
            new_population[i] = mutate(new_population[i])

    return new_population

if __name__ == "__main__":
    # Parámetros del algoritmo genético
    load_distances()
    city_count = 251
    population_size = 100
    generations = 100
    crossover_probability = 0.8
    mutation_probability = 0.2

    # Generar ciudades aleatorias en un espacio bidimensional
    cities = [(random.random(), random.random()) for _ in range(city_count)]

    # Inicializar la población
    population = [generate_random_route(city_count) for _ in range(population_size)]

    for generation in range(generations):
        # Dividir la población en subpoblaciones para paralelizar
        subpopulations = [population[i:i + len(population)//multiprocessing.cpu_count()] for i in range(0, len(population), len(population)//multiprocessing.cpu_count())]

        with multiprocessing.Pool() as pool:
            # Evaluar la aptitud en paralelo
            fitness_values_subpop = pool.starmap(evaluate_population, [(subpop, cities) for subpop in subpopulations])

            fitness_values = [item for sublist in fitness_values_subpop for item in sublist]

            # Obtener índices de los valores ordenados de menor a mayor
            indices_ordenados = sorted(range(len(fitness_values)), key=lambda i: fitness_values[i])
            
            # Elimina las subpoblaciones que no son las mejores
            population = [population[i] for i in indices_ordenados[:int(population_size/2)]]
            
            # Evolucionar la población en paralelo
            population = evolve_population(population, cities)

        # Seleccionar el mejor individuo de la generación
        best_route = min(population, key=lambda x: total_distance(x, cities))
        best_distance = total_distance(best_route, cities)

        print(f"Generación {generation + 1}: Mejor distancia = {best_distance}, Size: {len(population)}")

    print(f"Mejor ruta encontrada: {best_route}")
