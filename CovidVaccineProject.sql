SELECT * 
From PortfolioProject..CovidDeaths$
order by 3,4

--SELECT * 
--From PortfolioProject..CovidVaccinations$
--order by 3,4

-- Select Data that we are going to be using


Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths$
order by 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows Likelihood of dying if you contract covid in your country
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths$
Where location like '%states%'
order by 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid
Select Location, date, total_cases, Population, (total_cases/population)*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths$
-- Where location like '%states%'
order by 1,2

-- Looking at Countries with Highest Infection Rate Compared to Population
Select Location, Population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths$
-- Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc -- desc gives highest number first


-- Showing Countries with the highest Death Count per population
Select Location, MAX(cast(Total_deaths as int)) as TotalDeathsCount
From PortfolioProject..CovidDeaths$
-- Where location like '%states%'
Where continent is not null
Group by Location
order by TotalDeathsCount desc -- desc gives highest number first


-- LET'S BREAK THINGS DOWN BY CONTINENT

-- Showing Countries with the highest Death Count per population
Select continent, MAX(cast(Total_deaths as int)) as TotalDeathsCount
From PortfolioProject..CovidDeaths$
-- Where location like '%states%'
Where continent is not null
Group by continent
order by TotalDeathsCount desc -- desc gives highest number first


-- Showing the continents with the highest death count
Select continent, MAX(cast(Total_deaths as int)) as TotalDeathsCount
From PortfolioProject..CovidDeaths$
-- Where location like '%states%'
Where continent is not null
Group by continent
order by TotalDeathsCount desc -- desc gives highest number first


-- total cases by date
-- GLOBAL NUMBERS
Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage -- total_deaths, (total_cases/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths$
-- Where location like '%states%'
where continent is not null
Group by date
order by 1,2


-- just total cases
-- GLOBAL NUMBERS
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage -- total_deaths, (total_cases/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths$
-- Where location like '%states%'
where continent is not null
order by 1,2


-- Looking at Total Population vs Vaccinations
-- need to specify table pull from if both tables have same column name
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
From PortfolioProject..CovidDeaths$ dea
Join PortfolioProject..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

--add rolling count to vaccinations (sum new vaccinations vs. using total vaccinations)
	-- Partition by dea.Location runs only through each location (so runs through Canada and then resets)
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths$ dea
Join PortfolioProject..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3


-- USE CTE
-- number of columns in CTE must be equal to number of columns specified
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths$ dea
Join PortfolioProject..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

-- TEMP TABLE

-- use if you want to remake table
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255), 
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths$ dea
Join PortfolioProject..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating View to store data for later visualizations
Create View PercentPopulationVaccinated as 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths$ dea
Join PortfolioProject..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3