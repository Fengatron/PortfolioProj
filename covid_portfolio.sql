-- change data type from INT to NUMERIC
ALTER TABLE covid_deaths
    ALTER COLUMN population TYPE numeric,
	ALTER COLUMN total_cases TYPE NUMERIC,
	ALTER COLUMN new_cases TYPE NUMERIC, 
	ALTER COLUMN total_deaths TYPE NUMERIC, 
	ALTER COLUMN new_deaths TYPE NUMERIC, 
	ALTER COLUMN icu_patients TYPE NUMERIC, 
	ALTER COLUMN hosp_patients TYPE NUMERIC, 
	ALTER COLUMN weekly_hosp_admissions TYPE NUMERIC, 
	ALTER COLUMN weekly_icu_admissions TYPE NUMERIC;

-- Select data to be used
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid_deaths
WHERE continent IS NOT NULL
ORDER BY location, date;

-- Total cases vs total deaths in canada
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM covid_deaths
WHERE location = 'Canada'
ORDER BY location, date;

--Total cases vs population in canada
SELECT location, date, total_cases, population, (total_cases/population)*100 AS case_percentage
FROM covid_deaths
WHERE location = 'Canada'
ORDER BY location, date;

-- Countries with highest infection rate by population
SELECT location, MAX(total_cases) AS max_cases, population, MAX(total_cases/population)*100 AS pop_infection_percentage
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY location, population
HAVING MAX(total_cases/population)*100 > 0
ORDER BY pop_infection_percentage DESC;

--Countries with the highest deaths 
SELECT location, MAX(total_deaths) AS total_deaths 
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_deaths DESC;

--Highest deaths by continent
SELECT continent, MAX(total_deaths) AS total_deaths 
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_deaths DESC;

--Global death rate by day
SELECT date, SUM(new_cases) AS total_cases, 
SUM(new_deaths) AS total_deaths,
SUM(new_deaths)/SUM(new_cases)*100 AS death_percentage
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1;

--Global death rate total
SELECT SUM(new_cases) AS total_cases, 
SUM(new_deaths) AS total_deaths,
SUM(new_deaths)/SUM(new_cases)*100 AS death_percentage
FROM covid_deaths
WHERE continent IS NOT NULL
ORDER BY 1;

-- Total population vs vaccinations CTE
WITH PopvsVac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
AS(
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS rolling_people_vaccinated
FROM covid_deaths cd
JOIN covid_vaccinations cv
ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
ORDER BY 2,3
)
SELECT *, (rolling_people_vaccinated/population)*100 AS perc_rolling_vaccinated
FROM PopvsVac

-- Total population vs vaccinations temp table
DROP TABLE IF EXISTS Percent_population_vaccinated
CREATE TABLE Percent_population_vaccinated (
continent VARCHAR(50),
	location VARCHAR(50),
	date TIMESTAMP,
	population NUMERIC,
	new_vaccinations NUMERIC,
	rolling_people_vaccinated NUMERIC
	)
	
INSERT INTO Percent_population_vaccinated
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS rolling_people_vaccinated
FROM covid_deaths cd
JOIN covid_vaccinations cv
ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.continent IS NOT NULL

SELECT *, (rolling_people_vaccinated/population)*100 AS perc_rolling_vaccinated
FROM Percent_population_vaccinated

-- Creating views to store data for visualization
CREATE VIEW Percent_population_vaccinated_view AS
WITH PopvsVac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
AS(
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS rolling_people_vaccinated
FROM covid_deaths cd
JOIN covid_vaccinations cv
ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
ORDER BY 2,3
)
SELECT *, (rolling_people_vaccinated/population)*100 AS perc_rolling_vaccinated
FROM PopvsVac

CREATE VIEW total_death_continent AS
SELECT continent, MAX(total_deaths) AS total_deaths 
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_deaths DESC;
