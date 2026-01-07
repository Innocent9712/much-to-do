package config

import (
        "os"
        "strconv"
)

type Config struct {
        ServerPort         string
        MongoURI           string
        DBName             string
        JWTSecretKey       string
        JWTExpirationHours int
        EnableCache        bool
        RedisAddr          string
        RedisPassword      string
        LogLevel           string
        LogFormat          string
}

func LoadConfig(path string) (Config, error) {
        config := Config{
                ServerPort:         getEnv("PORT", "8080"),
                MongoURI:           getEnv("MONGO_URI", ""),
                DBName:             getEnv("DB_NAME", "muchtodo"),
                JWTSecretKey:       getEnv("JWT_SECRET_KEY", "default-secret-key"),
                JWTExpirationHours: getEnvAsInt("JWT_EXPIRATION_HOURS", 72),
                EnableCache:        getEnvAsBool("ENABLE_CACHE", false),
                RedisAddr:          getEnv("REDIS_ADDR", ""),
                RedisPassword:      getEnv("REDIS_PASSWORD", ""),
                LogLevel:           getEnv("LOG_LEVEL", "info"),
                LogFormat:          getEnv("LOG_FORMAT", "json"),
        }
        return config, nil
}

func getEnv(key, defaultValue string) string {
        if value := os.Getenv(key); value != "" {
                return value
        }
        return defaultValue
}

func getEnvAsInt(key string, defaultValue int) int {
        valueStr := getEnv(key, "")
        if value, err := strconv.Atoi(valueStr); err == nil {
                return value
        }
        return defaultValue
}

func getEnvAsBool(key string, defaultValue bool) bool {
        valueStr := getEnv(key, "")
        if valueStr == "true" || valueStr == "1" {
                return true
        }
        if valueStr == "false" || valueStr == "0" {
                return false
        }
        return defaultValue
}
