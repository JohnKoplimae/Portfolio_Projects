SELECT * FROM covid_deaths;

SELECT * FROM covid_vacc;

-- Select Data that we are ging to be using
SELECT location, day, total_cases, new_cases, total_deaths, population
FROM covid_deaths
ORDER BY 1,2;

-- Looking at the Total cases vs. Total Deaths
-- Precentage of deaths for cases of covid in Canada.
SELECT location, day, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100, 3) AS Death_Percentage
FROM covid_deaths
WHERE location = 'Canada'
AND continent IS NOT NULL
ORDER BY 1,2;

-- Looking at Total Cases vs Population
-- Shows what percentage of the population that got Covid
SELECT location, day, total_cases, population, ROUND((total_cases/population)*100, 3) AS Covid_Percentage
FROM covid_deaths
WHERE location = 'Canada'
AND continent IS NOT NULL
ORDER BY 1,2;

-- What countries have the highest infection rate compared to its population
SELECT location, population, MAX(total_cases)AS Highest_Infection_Count, MAX(ROUND((total_cases/population)*100, 3)) AS Infection_Percentage
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY Infection_Percentage DESC NULLS LAST;

-- Countries with the Highest Death Count.
SELECT location, MAX(total_deaths)AS Total_Death_Count
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY Total_Death_Count DESC NULLS LAST;

-- Continent Death Count.
SELECT location, MAX(total_deaths)AS Total_Death_Count
FROM covid_deaths
WHERE continent IS NULL
GROUP BY location
ORDER BY Total_Death_Count DESC;

-- Global Numbers
SELECT day, SUM(new_cases) AS Case_Count, SUM(new_deaths) AS Death_Count, ROUND(SUM(new_deaths)/SUM(new_cases)*100, 3) AS Death_Percentage
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY day
ORDER BY 1,2;

-- Total Covid cases worldwide to date.
SELECT SUM(new_cases) AS Case_Count, SUM(new_deaths) AS Death_Count, ROUND(SUM(new_deaths)/SUM(new_cases)*100, 3) AS Death_Percentage
FROM covid_deaths
WHERE continent IS NOT NULL
ORDER BY 1,2;

-- Total Poplulation vs Vaccinations
SELECT D.continent, D.location, D.day, D.population, V.new_vaccinations, SUM(V.new_vaccinations) OVER (PARTITION BY D.location ORDER BY D.location, D.day) AS Rolling_vac_total
FROM covid_deaths D
JOIN covid_vacc V
    ON D.location = V.location
    AND D.day = V.day
WHERE continent IS NOT NULL
ORDER BY 2,3;

-- Showing rolling new vaccination totals and percentage for each country. Using a CTE
WITH PopvsVac (continent, lcoation, day, population, new_vaccinations, Rolling_vac_total)
AS
(
SELECT D.continent, D.location, D.day, D.population, V.new_vaccinations, SUM(V.new_vaccinations) OVER (PARTITION BY D.location ORDER BY D.location, D.day) AS Rolling_vac_total
FROM covid_deaths D
JOIN covid_vacc V
    ON D.location = V.location
    AND D.day = V.day
WHERE continent IS NOT NULL
)
SELECT *, (Rolling_vac_total/population)*100 AS Percent_vaccinated FROM PopvsVac;

-- Creating view to store data for later visualizations
CREATE VIEW PopulationVaccinated AS
SELECT D.continent, D.location, D.day, D.population, V.new_vaccinations, SUM(V.new_vaccinations) OVER (PARTITION BY D.location ORDER BY D.location, D.day) AS Rolling_vac_total
FROM covid_deaths D
JOIN covid_vacc V
    ON D.location = V.location
    AND D.day = V.day
WHERE D.continent IS NOT NULL;

