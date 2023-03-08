/*
COVID-19 Data Exploration 
Skills used: Joins, CTE's, Aggregate Functions, Creating Views, Converting Data Types
*/

-- GENERAL DATA
-- Select all covid data
SELECT *
FROM covid_deaths
WHERE continent != ''
ORDER BY location;


-- Select starting data
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid_deaths
WHERE continent != ''
ORDER BY 1,2;


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as mortality_rate
FROM covid_deaths
WHERE location = 'United States' AND continent != ''
ORDER BY 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid
SELECT location, date, population, total_cases, (total_cases/population)*100 as infection_rate
FROM covid_deaths
ORDER BY 1,2


-- Countries with Highest Infection Rate compared to Population
Select location, population, MAX(total_cases) as highest_case_count,  Max((total_cases/population))*100 as infection_rate
FROM covid_deaths
GROUP BY location, population
ORDER BY infection_rate DESC


-- Countries with Highest Death Count per Population
SELECT location, MAX(total_deaths) as total_deaths
FROM covid_deaths
WHERE continent != ''
GROUP BY location
ORDER BY total_deaths DESC



-- CONTINENT BREAKDOWN
-- Showing contintents with the highest death count per population
SELECT continent, MAX(total_deaths)::int as total_deaths_max
FROM covid_deaths
WHERE continent != ''
GROUP BY continent
ORDER BY total_deaths_max DESC



-- GLOBAL NUMBERS
SELECT SUM(new_cases)::int as new_cases_total, SUM(new_deaths)::int as new_deaths_total, SUM(new_deaths)/SUM(new_cases)*100 as death_rate
FROM covid_deaths
WHERE continent != '' 
-- GROUP BY date
ORDER BY 1,2


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine cumulatively
SELECT dea.continent, dea.location, dea.date, dea.population::bigint, vax.new_vaccinations::real,
	SUM(vax.new_vaccinations::real::bigint) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
	as vaccinations_cumulative
FROM covid_deaths as dea
JOIN covid_vax as vax
	ON dea.location = vax.location
	AND dea.date = vax.date
WHERE dea.continent != '' AND vax.new_vaccinations !=''
ORDER BY 2, 3



-- GDP AND DEATHS
-- mortality by GDP per capita
-- removed countries with incomplete GDP / COVID data
SELECT location, MAX(population::bigint) as population, MAX(ROUND(gdp_per_capita)) as gdp_per_capita,
	CASE 
		WHEN MAX(ROUND(gdp_per_capita)) <= 1045 THEN 'Low Income'
		WHEN MAX(ROUND(gdp_per_capita)) <= 4095 THEN 'Lower-Middle Income'
		WHEN MAX(ROUND(gdp_per_capita)) <= 12695 THEN 'Upper-Middle Income'
		WHEN MAX(ROUND(gdp_per_capita)) > 12695 THEN 'High Income'
		ELSE ''
	END AS gdp_category,
	MAX(total_cases) as total_cases,
	MAX(total_deaths) as total_deaths_current, (MAX(total_deaths)::real / MAX(total_cases)::real)*100 as mortality_rate
FROM covid_deaths
WHERE continent != '' AND gdp_per_capita IS NOT NULL AND total_cases IS NOT NULL AND total_deaths IS NOT NULL
GROUP BY 1
ORDER BY mortality_rate DESC



-- GDP AND VACCINATION
-- find vaccination rate by GDP
SELECT dea.location, MAX(dea.population::bigint) as population, MAX(ROUND(dea.gdp_per_capita)) as gdp_per_capita,
	CASE 
		WHEN MAX(ROUND(dea.gdp_per_capita)) <= 1045 THEN 'Low Income'
		WHEN MAX(ROUND(dea.gdp_per_capita)) <= 4095 THEN 'Lower-Middle Income'
		WHEN MAX(ROUND(dea.gdp_per_capita)) <= 12695 THEN 'Upper-Middle Income'
		WHEN MAX(ROUND(dea.gdp_per_capita)) > 12695 THEN 'High Income'
		ELSE ''
	END AS gdp_category,
	MAX(vax.total_vaccinations::real::bigint) as total_vaccinations, MAX(vax.people_vaccinated::real::int) as pop_vaccinated, 
	MAX(vax.people_fully_vaccinated::real::int) as pop_fully_vaccinated, MAX(vax.total_boosters::real::int) as pop_boosted,
	(MAX(vax.people_fully_vaccinated::real::int) / MAX(dea.population)*100) as vaccination_rate
FROM covid_deaths as dea
JOIN covid_vax as vax
	ON dea.location = vax.location
	AND dea.date = vax.date
WHERE dea.continent != '' AND dea.gdp_per_capita IS NOT NULL AND vax.people_fully_vaccinated != '' 
AND vax.total_boosters != '' AND vax.total_vaccinations != '' AND vax.people_vaccinated != ''
GROUP BY 1
ORDER BY vaccination_rate DESC



-- VIEWS
-- Deaths
CREATE VIEW gdp_deaths as
SELECT location, MAX(population::bigint) as population, MAX(ROUND(gdp_per_capita)) as gdp_per_capita,
	CASE 
		WHEN MAX(ROUND(gdp_per_capita)) <= 1045 THEN 'Low Income'
		WHEN MAX(ROUND(gdp_per_capita)) <= 4095 THEN 'Lower-Middle Income'
		WHEN MAX(ROUND(gdp_per_capita)) <= 12695 THEN 'Upper-Middle Income'
		WHEN MAX(ROUND(gdp_per_capita)) > 12695 THEN 'High Income'
		ELSE ''
	END AS gdp_category,
	MAX(total_cases) as total_cases,
	MAX(total_deaths) as total_deaths_current, (MAX(total_deaths)::real / MAX(total_cases)::real)*100 as mortality_rate
FROM covid_deaths
WHERE continent != '' AND gdp_per_capita IS NOT NULL AND total_cases IS NOT NULL AND total_deaths IS NOT NULL
GROUP BY 1
ORDER BY mortality_rate DESC;
SELECT *
FROM gdp_deaths


-- Vaccinations
CREATE VIEW gdp_vaccination as
SELECT dea.location, MAX(dea.population::bigint) as population, MAX(ROUND(dea.gdp_per_capita)) as gdp_per_capita,
	CASE 
		WHEN MAX(ROUND(dea.gdp_per_capita)) <= 1045 THEN 'Low Income'
		WHEN MAX(ROUND(dea.gdp_per_capita)) <= 4095 THEN 'Lower-Middle Income'
		WHEN MAX(ROUND(dea.gdp_per_capita)) <= 12695 THEN 'Upper-Middle Income'
		WHEN MAX(ROUND(dea.gdp_per_capita)) > 12695 THEN 'High Income'
		ELSE ''
	END AS gdp_category,
	MAX(vax.total_vaccinations::real::bigint) as total_vaccinations, MAX(vax.people_vaccinated::real::int) as pop_vaccinated, 
	MAX(vax.people_fully_vaccinated::real::int) as pop_fully_vaccinated, MAX(vax.total_boosters::real::int) as pop_boosted,
	(MAX(vax.people_fully_vaccinated::real::int) / MAX(dea.population)*100) as vaccination_rate
FROM covid_deaths as dea
JOIN covid_vax as vax
	ON dea.location = vax.location
	AND dea.date = vax.date
WHERE dea.continent != '' AND dea.gdp_per_capita IS NOT NULL AND vax.people_fully_vaccinated != '' 
AND vax.total_boosters != '' AND vax.total_vaccinations != '' AND vax.people_vaccinated != ''
GROUP BY 1
ORDER BY vaccination_rate DESC;
SELECT *
FROM gdp_vaccination

-- Continent Breakdown
CREATE VIEW continent_deaths as
SELECT continent, MAX(total_deaths)::int as total_deaths_max
FROM covid_deaths
WHERE continent != ''
GROUP BY continent
ORDER BY total_deaths_max DESC;
SELECT *
FROM continent_deaths