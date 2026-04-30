package unica.ds4h.rosset.statsservice;

import io.github.resilience4j.common.circuitbreaker.configuration.CircuitBreakerConfigCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;

@Configuration
public class AppConfig {

    @Bean
    public RestTemplate restTemplate() {
        return new RestTemplate();
    }

    @Bean
    public CircuitBreakerConfigCustomizer playerServiceCBCustomizer() {
        return CircuitBreakerConfigCustomizer.of("playerService", builder ->
            builder.recordExceptions(Exception.class)
        );
    }
}
