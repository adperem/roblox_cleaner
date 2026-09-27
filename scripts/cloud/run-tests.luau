-- Script que scripts/roblox_cloud.py envía a la API Luau Execution de Open
-- Cloud. Corre dentro de un servidor de Roblox de verdad, cargado con la
-- versión del lugar recién subida; los scripts del lugar no se ejecutan
-- solos ahí, así que el único arranque del servidor es el de las pruebas.
-- Si alguna falla, Runner lanza un error y la tarea termina en FAILED.

local ServerStorage = game:GetService("ServerStorage")

local Runner = require(ServerStorage.Tests.Runner)

return Runner.run(true)
