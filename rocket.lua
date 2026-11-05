-- Автопилот стабилизации ракеты (ComputerCraft + Vector Thrusters + Gimbal Sensor)

local gimbal = peripheral.find("gimbal_sensor")
if not gimbal then
    error("❌ Гироскоп gimbal_sensor не найден!")
end

-- Подключаем 4 векторных двигателя по их индексам
local thrusters = {
    [0] = peripheral.wrap("vector_thruster_0"), -- слева спереди
    [1] = peripheral.wrap("vector_thruster_1"), -- слева сзади
    [2] = peripheral.wrap("vector_thruster_2"), -- справа спереди
    [3] = peripheral.wrap("vector_thruster_3")  -- справа сзади
}

-- Проверяем подключение двигателей
for i = 0, 3 do
    if not thrusters[i] then
        print("⚠️ Внимание: vector_thruster_" .. i .. " не найден!")
    end
end

local THRESHOLD = 10   -- Порог срабатывания в градусах (если больше ±10°, включается выравнивание)
local BASE_POWER = 30  -- Базовая тяга двигателей во время полёта
local k = 1.5          -- Коэффициент усиления коррекции

-- Функция ограничения мощности в пределах от 0 до 100
local function clamp(val)
    return math.max(0, math.min(100, val))
end

print("🚀 Автопилот стабилизации запущен. Ожидание отклонений...")

while true do
    -- Получаем углы с гироскопа (поддерживаем разные варианты возврата значений)
    local success, x, y, z = pcall(gimbal.getAngles)
    if not success or not x then
        local angles = {gimbal.getAngles()}
        x, y, z = angles[1], angles[2], angles[3]
    end

    if x and z then
        -- Проверяем, превышает ли отклонение по X или Z заданный порог в 10 градусов
        if math.abs(x) > THRESHOLD or math.abs(z) > THRESHOLD then
            -- Пропорциональное распределение мощности для компенсации крена (X) и тангажа (Z)
            local corrX = x * k
            local corrZ = z * k

            -- Распределяем тягу по моторам с учетом их расположения по углам ракеты
            local p0 = BASE_POWER - corrX - corrZ -- Слева спереди
            local p1 = BASE_POWER - corrX + corrZ -- Слева сзади
            local p2 = BASE_POWER + corrX - corrZ -- Справа спереди
            local p3 = BASE_POWER + corrX + corrZ -- Справа сзади

            -- Применяем мощность к двигателям
            if thrusters[0] then thrusters[0].setPower(clamp(p0)) end
            if thrusters[1] then thrusters[1].setPower(clamp(p1)) end
            if thrusters[2] then thrusters[2].setPower(clamp(p2)) end
            if thrusters[3] then thrusters[3].setPower(clamp(p3)) end

            print(string.format("⚖️ Коррекция наклона -> X: %.1f° | Z: %.1f°", x, z))
        else
            -- Если ракета летит ровно (в пределах ±10°), держим равную базовую тягу на всех двигателях
            for i = 0, 3 do
                if thrusters[i] then
                    thrusters[i].setPower(BASE_POWER)
                end
            end
        end
    end

    sleep(0.05) -- Опрос датчика 20 раз в секунду для плавной стабилизации
end
