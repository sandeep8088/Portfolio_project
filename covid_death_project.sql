CREATE TABLE coviddeath (
    iso_code TEXT,
    continent TEXT,
    location TEXT,
    date DATE,
    population BIGINT,
	total_cases INTEGER,
    new_cases INTEGER,
    new_cases_smoothed NUMERIC,
    total_deaths INTEGER,
    new_deaths INTEGER,
    new_deaths_smoothed NUMERIC,
    total_cases_per_million NUMERIC,
    new_cases_per_million NUMERIC,
    new_cases_smoothed_per_million NUMERIC,
    total_deaths_per_million NUMERIC,
    new_deaths_per_million NUMERIC,
    new_deaths_smoothed_per_million NUMERIC,
    reproduction_rate NUMERIC,
    icu_patients INTEGER,
    icu_patients_per_million NUMERIC,
    hosp_patients INTEGER,
    hosp_patients_per_million NUMERIC,
    weekly_icu_admissions INTEGER,
    weekly_icu_admissions_per_million NUMERIC,
    weekly_hosp_admissions INTEGER,
    weekly_hosp_admissions_per_million NUMERIC
  
);
ALTER TABLE coviddeath
ALTER COLUMN weekly_hosp_admissions TYPE NUMERIC;

ALTER TABLE coviddeath
ALTER COLUMN weekly_icu_admissions TYPE FLOAT;

select * from coviddeath




CREATE TABLE covid_vaccination (
    iso_code TEXT,
    continent TEXT,
    location TEXT,
    date DATE,
    new_tests NUMERIC,
    total_tests NUMERIC,
    total_tests_per_thousand NUMERIC,
    new_tests_per_thousand NUMERIC,
    new_tests_smoothed NUMERIC,
    new_tests_smoothed_per_thousand NUMERIC,
    positive_rate NUMERIC,
    tests_per_case NUMERIC,
    tests_units TEXT,
    total_vaccinations NUMERIC,
    people_vaccinated NUMERIC,
    people_fully_vaccinated NUMERIC,
    new_vaccinations NUMERIC,
    new_vaccinations_smoothed NUMERIC,
    total_vaccinations_per_hundred NUMERIC,
    people_vaccinated_per_hundred NUMERIC,
    people_fully_vaccinated_per_hundred NUMERIC,
    new_vaccinations_smoothed_per_million NUMERIC,
    stringency_index NUMERIC,
    population_density NUMERIC,
    median_age NUMERIC,
    aged_65_older NUMERIC,
    aged_70_older NUMERIC,
    gdp_per_capita NUMERIC,
    extreme_poverty NUMERIC,
    cardiovasc_death_rate NUMERIC,
    diabetes_prevalence NUMERIC,
    female_smokers NUMERIC,
    male_smokers NUMERIC,
    handwashing_facilities NUMERIC,
    hospital_beds_per_thousand NUMERIC,
    life_expectancy NUMERIC,
    human_development_index NUMERIC
);

select * from covid_vaccination where continent is not null order by 3,4



select location, date, total_cases, new_cases, total_deaths, population from coviddeath order by 1,2

-- looking total cases vs total deaths
--shows likelihood of dying in my country

SELECT 
    location, 
    date, 
    total_cases, 
    total_deaths, 
    (total_deaths::NUMERIC / NULLIF(total_cases, 0)::NUMERIC) * 100 AS DeathPercentage
FROM coviddeath where location = 'India'
ORDER BY 1,2 ;

--Looking at total cases vs population 
--looking number of sace percengage in my country
SELECT 
    location, 
    date, 
    total_cases, 
    total_deaths,
	population,
    (total_cases::NUMERIC / NULLIF(population, 0)::NUMERIC) * 100 AS EffectedPercentage

FROM coviddeath where location = 'India'
ORDER BY 1,2 ;


--looking at countries with highest infection rate compared to population
SELECT 
    location, 
    MAX(total_cases) AS HighestInfectionCount, 
    MAX((total_cases * 100.0 / population))::numeric AS percentpopulationaffected
FROM 
    coviddeath
GROUP BY 
    location, population
ORDER BY 
    percentpopulationaffected DESC;


-- showing continent with highest death count per population

SELECT 
    continent, 
    MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM 
    coviddeath
where continent is not null
GROUP BY 
    continent
ORDER BY 
    TotalDeathCount desc;


-- Global numbers 

SELECT 
    SUM(new_cases) AS total_cases, 
    SUM(CAST(new_deaths AS int)) AS total_deaths, 
    (SUM(CAST(new_deaths AS int))::decimal / NULLIF(SUM(new_cases), 0)) * 100 AS DeathPercentage
FROM 
    coviddeath 
WHERE 
    continent IS NOT NULL;


-- looking at total population vs vaccination 
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations, 
    SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM 
    coviddeath dea 
JOIN 
    covid_vaccination vac 
ON 
    dea.location = vac.location AND dea.date = vac.date 
WHERE 
    dea.continent IS NOT NULL 
ORDER BY 
    dea.location, dea.date;


-- use cte

WITH PopvsVac AS (
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(vac.new_vaccinations) OVER (
            PARTITION BY dea.location 
            ORDER BY dea.date
        ) AS RollingPeopleVaccinated
    FROM 
        coviddeath dea
    JOIN 
        covid_vaccination vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE 
        dea.continent IS NOT NULL
)
SELECT 
    *,
    (RollingPeopleVaccinated / population::NUMERIC) * 100 AS VaccinationPercentage
FROM 
    PopvsVac;


-- Using Temp Table to perform Calculation on Partition By in previous query

-- Drop the temporary table if it exists
DROP TABLE IF EXISTS PercentPopulationVaccinated;

-- Create the temporary table
CREATE TEMP TABLE PercentPopulationVaccinated (
    Continent VARCHAR(255),
    Location VARCHAR(255),
    Date DATE,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

-- Insert data into the temporary table
INSERT INTO PercentPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (
        PARTITION BY dea.location 
        ORDER BY dea.date
    ) AS RollingPeopleVaccinated
FROM 
    coviddeath dea
JOIN 
    covid_vaccination vac
    ON dea.location = vac.location
    AND dea.date = vac.date;

-- Query the data, calculating the vaccination percentage
SELECT 
    *, 
    (RollingPeopleVaccinated / population) * 100 AS VaccinationPercentage
FROM 
    PercentPopulationVaccinated;


-- Creating a view for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (
        PARTITION BY dea.location 
        ORDER BY dea.date
    ) AS RollingPeopleVaccinated
FROM 
    coviddeath dea
JOIN 
    covid_vaccination vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL;


select * from PercentPopulationVaccinated




















