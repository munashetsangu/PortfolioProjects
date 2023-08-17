select * 
from PortfolioProject.dbo.coviddeaths
order by 3,4

--select * 
--from PortfolioProject.dbo.CovidVaccinations
--order by 3,4


-- Looking at Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract Covid in your Country

select location, date, total_cases, total_deaths, (total_deaths/total_cases)* 100 as DeathPercentage
from PortfolioProject.dbo.CovidDeaths
Where location like '%Zimbabwe%'
order by 1,2



-- Looking at Total Cases vs Population
-- Shows what percentage of Population got Covid

select location, date, population,total_cases, (total_cases/population)* 100 as PercentPopulationInfected
from PortfolioProject.dbo.CovidDeaths
Where location like '%Zimbabwe%'
order by 1,2



-- Looking at Countries with Highest Infection Rate compared to Population

select location, population, MAX(total_cases), MAX((total_cases/population))* 100 as PercentPopulationInfected
from PortfolioProject.dbo.CovidDeaths
--Where location like '%Zimbabwe%'
Group by location, population
order by PercentPopulationInfected Desc



-- Showing the Countries with the Highest Death Count Per Population

select location, Max(CAST(total_deaths as int)) as TotalDeathCount
from PortfolioProject.dbo.CovidDeaths
--Where location like '%Zimbabwe%'
Where Continent is not null 
Group by location
order by TotalDeathCount desc


-- Showing Results By Continent 

select Continent, Max(CAST(total_deaths as int)) as TotalDeathCount
from PortfolioProject.dbo.CovidDeaths
--Where location like '%Zimbabwe%'
Where Continent is not null
Group by continent
order by TotalDeathCount desc



-- Global Numbers

select SUM(new_cases) as total_cases, SUM(CAST(new_deaths as int)) as total_deaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
from PortfolioProject.dbo.CovidDeaths
--Where location like '%Zimbabwe%'
Where continent is not null
--Group by date
order by 1,2




--Looking at Total Population Vs Vaccination

--USE CTE

With PopulationVsVaccinations (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
As
(
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	SUM(CAST (cv.new_vaccinations as int)) OVER (PARTITION BY cd.location Order by cd.location, cd.date) as RollingPeopleVaccinated 
from PortfolioProject.dbo.CovidDeaths  cd
Join PortfolioProject.dbo.CovidVaccinations  cv
	ON cd.location = cv.location
	and cd.date =cv.date
Where cd.continent is not null
--Order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100 as PercentPopulationVaccinated
From PopulationVsVaccinations




-- Creating View to Store Data for Later Visualizations

Create View PercentPopulationVaccinated as
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	SUM(CAST (cv.new_vaccinations as int)) OVER (PARTITION BY cd.location Order by cd.location, cd.date) as RollingPeopleVaccinated 
from PortfolioProject.dbo.CovidDeaths  cd
Join PortfolioProject.dbo.CovidVaccinations  cv
	ON cd.location = cv.location
	and cd.date =cv.date
Where cd.continent is not null

