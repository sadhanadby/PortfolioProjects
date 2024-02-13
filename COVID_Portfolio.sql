CREATE DATABASE PortfolioProject;
Use PortfolioProject;

-- created covid_deaths table
Create Table covid_deaths (
	iso_code varchar(255) null,
    continent VARCHAR(10),
    location VARCHAR(50),
    date datetime,
    population bigint,
    total_cases int,
    new_cases int,
    new_cases_smoothed int,
    total_deaths int,
    new_deaths int,
    new_deaths_smoothed int,
    total_cases_per_million float,
    new_cases_per_million float,
    new_cases_smoothed_per_million	float,
    total_deaths_per_million float,
    new_deaths_per_million	float,
    new_deaths_smoothed_per_million	float,
    reproduction_rate	float,
    icu_patients int,
    icu_patients_per_million	float,
    hosp_patients	int,
    hosp_patients_per_million	float,
    weekly_icu_admissions	int,
    weekly_icu_admissions_per_million	float,
    weekly_hosp_admissions	int,
    weekly_hosp_admissions_per_million float
);
drop table covid_deaths;
-- Error Code: 3948. Loading local data is disabled; this must be enabled on both the client and server sides
SHOW global variables like 'local_infile';
set global local_infile = true;

-- Load covid_deaths csv Data
LOAD DATA LOCAL INFILE 'D:/Sadhana/Resources/CovidDeaths.csv'
INTO TABLE covid_deaths
FIELDS TERMINATED BY ','
IGNORE 1 ROWS;

-- Matched count of covid_deaths record
Select * From covid_deaths
where continent is not null;

-- created covid_vaccinations table
Create Table covid_vaccinations (
	iso_code	varchar(10),
    continent	varchar(10),
    location	varchar(50),
    date	datetime,
    new_tests	int,
    total_tests	int,
    total_tests_per_thousand	float,
    new_tests_per_thousand	float,
    new_tests_smoothed	int,
    new_tests_smoothed_per_thousand float,	
    positive_rate	float,
    tests_per_case	float,
    tests_units	varchar(50),
    total_vaccinations	int,
    people_vaccinated	int,
    people_fully_vaccinated	int,
    new_vaccinations	int,
    new_vaccinations_smoothed	int,
    total_vaccinations_per_hundred	float,
    people_vaccinated_per_hundred	float,
    people_fully_vaccinated_per_hundred	float,
    new_vaccinations_smoothed_per_million	int,
    stringency_index	float,
    population_density	float,
    median_age	float,
    aged_65_older	float,
    aged_70_older	float,
    gdp_per_capita	float,
    extreme_poverty	float,
    cardiovasc_death_rate	float,
    diabetes_prevalence	float,
    female_smokers	float,
    male_smokers	float,
    handwashing_facilities	float,
    hospital_beds_per_thousand	float,
    life_expectancy	float,
    human_development_index float
);

-- Load covid_vaccinations csv Data
LOAD DATA LOCAL INFILE 'D:/Sadhana/Resources/CovidVaccinations.csv'
INTO TABLE covid_vaccinations
FIELDS TERMINATED BY ','
IGNORE 1 ROWS;

Select * From covid_vaccinations;

Select Location, date, total_cases, new_cases, total_Deaths, population 
From covid_deaths
order by 1,2;

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
Select Location, date, total_cases, total_Deaths, 100*(total_deaths/total_cases) as 'DeathPercentage'
From covid_deaths
Where Location like 'India'
order by 1,2;


-- Total cases vs Population
-- what percentage of population got covid
Select Location, date, total_cases, Population, 100*(total_cases/population) as 'PercentagePopulationInfected'
From covid_deaths
Where Location like 'India'
order by 1,2;

-- Countries with highest infection rate compared to population
Select Location, Population, Max(total_cases) as 'HighestInfectionCount', total_Deaths, Max((total_cases/population))*100 as 'PercentagePopulationInfected'
From covid_deaths
Group By Location, Population
order by PercentagePopulationInfected desc;

-- Countries with Highest Death count per population
Select Location, Max(total_Deaths) as 'TotalDeathCount'
From covid_deaths
Where continent <> ""
Group By Location
order by TotalDeathCount desc;

-- Group data based on Continent
-- Continents with the highest death count per population
Select Continent, Max(total_Deaths) as 'TotalDeathCount'
From covid_deaths
Where continent <> ""
Group By Continent
order by TotalDeathCount desc;

-- Global data
Select sum(new_cases) 'total_cases', Sum(new_deaths)'total_deaths', (Sum(new_deaths)/sum(new_cases))*100 as 'DeathPercentage'
From covid_deaths
where continent <> ""
order by 1,2;


-- join covid_deaths and covid_vaccinations table
Select *
From covid_deaths cd
Join covid_vaccinations cv
On cd.location = cv.location and cd.date = cv.date;

-- Total Population vs Vaccination
Select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
	   Sum(new_vaccinations) Over (partition by cd.location order by cd.location, cd.date) as 'RollingPeopleVaccinated'
From covid_deaths cd
Join covid_vaccinations cv
On cd.location = cv.location and cd.date = cv.date
Where cd.continent <> ""
Order by 2,3;

-- Using CTE for finding how many people got vaccinated

With PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
as (
Select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
	   Sum(new_vaccinations) Over (partition by cd.location order by cd.location, cd.date) as 'RollingPeopleVaccinated'
From covid_deaths cd
Join covid_vaccinations cv
On cd.location = cv.location and cd.date = cv.date
Where cd.continent <> ""
)
Select *, (RollingPeopleVaccinated/Population) * 100
From PopvsVac;

-- Temp table to see how many people got vaccinated

Drop table if exists PercentPopulationVaccinated;

Create Temporary Table PercentPopulationVaccinated 
(
	Continent varchar(50),
	location varchar(50),
	date datetime,
	population int,
	new_vaccinations int,
	RollingPeopleVaccinated int
);

Insert Into PercentPopulationVaccinated
(
Select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
	   Sum(new_vaccinations) Over (partition by cd.location order by cd.location, cd.date) as 'RollingPeopleVaccinated'
From covid_deaths cd
Join covid_vaccinations cv
On cd.location = cv.location and cd.date = cv.date
);

Select *, (RollingPeopleVaccinated/Population) * 100
From PercentPopulationVaccinated;


-- Created view to store data for visualization
Create view PercentPopulationVaccinated as 
Select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
	   Sum(new_vaccinations) Over (partition by cd.location order by cd.location, cd.date) as 'RollingPeopleVaccinated'
From covid_deaths cd
Join covid_vaccinations cv
On cd.location = cv.location and cd.date = cv.date;