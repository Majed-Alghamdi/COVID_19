-- COVID 19 data to performe some skills.

-- Perpearing The data we are going to use from both datasets which only includes gulf countries numbers


-- COVIDDEATH DATA

SELECT
location, CAST(date AS date) as date, CAST(population AS INT) AS population, total_cases, 
total_deaths, new_cases, new_deaths
INTO #GulfDeaths
FROM COVIDDEATHS

WHERE (location LIKE 'Sau%' 
OR location LIKE '%Emirates' 
OR location LIKE '%qatar' 
OR location LIKE 'yem%' 
OR location LIKE '%bahr%' 
OR location LIKE '%kuw%'
OR location LIKE '%Oman')
--AND total_deaths IS NOT NULL

ORDER BY location

----------------------------------------------


-- COVID VACCINATION DATA

SELECT
location, CAST(date AS date) as date, new_vaccinations
INTO #GulfVacc
FROM COVIDVACC

WHERE (location LIKE 'Sau%' 
OR location LIKE '%Emirates' 
OR location LIKE '%qatar' 
OR location LIKE 'yem%' 
OR location LIKE '%bahr%' 
OR location LIKE '%kuw%'
OR location LIKE '%Oman')
--AND new_vaccinations IS NOT NULL

ORDER BY location

----------------------------------------------



-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in eash country

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From #GulfDeaths
order by 1,2 DESC



Select Location, date, Population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
From #GulfDeaths
order by PercentPopulationInfected DESC



-- Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount, round(Max(total_cases/population)*100,4) as PercentInfected
From #GulfDeaths
Group by Location, Population
order by PercentInfected desc


Select date, Location, Population, MAX(total_cases) as HighestInfectionCount, round(Max(total_cases/population)*100,4) as PercentInfected
From #GulfDeaths
Group by date, Location, Population
order by PercentInfected desc




-- Highest Death count compared to Population

Select location,population, SUM(CAST(new_deaths as INT)) as TotalDeathCount 
From #GulfDeaths
Group by location, population
order by TotalDeathCount desc



-- Gulf countries numbers

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From #GulfDeaths
order by 1,2



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From #GulfDeaths dea
Join #GulfVacc vac
	On dea.location = vac.location
	and dea.date = vac.date

order by 2,3




-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
as
(
Select dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From #GulfDeaths dea
Join #GulfVacc vac
	On dea.location = vac.location
	and dea.date = vac.date

)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac





-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select  dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From #GulfDeaths dea
Join #GulfVacc vac
	On dea.location = vac.location
	and dea.date = vac.date

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

SELECT * FROM #PercentPopulationVaccinated




-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From #GulfDeaths dea
Join #GulfVacc vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.population IS NOT NULL 