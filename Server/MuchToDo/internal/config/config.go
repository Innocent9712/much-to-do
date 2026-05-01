package config

import (
	"github.com/spf13/viper"
)

// Config stores all configuration of the application.
type Config struct {
	ServerPort         string `mapstructure:"PORT"`
	MongoURI           string `mapstructure:"MONGO_URI"`
	DBName             string `mapstructure:"DB_NAME"`
	JWTSecretKey       string `mapstructure:"JWT_SECRET_KEY"`
	JWTExpirationHours int    `mapstructure:"JWT_EXPIRATION_HOURS"`
	EnableCache        bool   `mapstructure:"ENABLE_CACHE"`
	RedisAddr          string `mapstructure:"REDIS_ADDR"`
	RedisPassword      string `mapstructure:"REDIS_PASSWORD"`
	LogLevel           string `mapstructure:"LOG_LEVEL"`
	LogFormat          string `mapstructure:"LOG_FORMAT"`
}

// LoadConfig reads configuration from file or environment variables.
func LoadConfig(path string) (config Config, err error) {
	viper.AddConfigPath(path)
	viper.SetConfigName(".env")
	viper.SetConfigType("env")

	viper.AutomaticEnv()

	// Bind environment variables so viper.Unmarshal can read Docker env values.
	_ = viper.BindEnv("PORT")
	_ = viper.BindEnv("MONGO_URI")
	_ = viper.BindEnv("DB_NAME")
	_ = viper.BindEnv("JWT_SECRET_KEY")
	_ = viper.BindEnv("JWT_EXPIRATION_HOURS")
	_ = viper.BindEnv("ENABLE_CACHE")
	_ = viper.BindEnv("REDIS_ADDR")
	_ = viper.BindEnv("REDIS_PASSWORD")
	_ = viper.BindEnv("LOG_LEVEL")
	_ = viper.BindEnv("LOG_FORMAT")

	// Set default values.
	viper.SetDefault("PORT", "8080")
	viper.SetDefault("ENABLE_CACHE", false)
	viper.SetDefault("JWT_EXPIRATION_HOURS", 72)
	viper.SetDefault("LOG_LEVEL", "INFO")
	viper.SetDefault("LOG_FORMAT", "text")

	err = viper.ReadInConfig()
	if err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
			return
		}
	}

	err = viper.Unmarshal(&config)
	return
}
