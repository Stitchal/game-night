package unica.ds4h.rosset.statsservice.service;

import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import io.github.resilience4j.retry.annotation.Retry;
import org.springframework.cloud.client.ServiceInstance;
import org.springframework.cloud.client.discovery.DiscoveryClient;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpMethod;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import unica.ds4h.rosset.statsservice.model.PartyStats;

import java.util.List;
import java.util.Map;

@Service
public class StatsService {

    private final RestTemplate restTemplate;
    private final DiscoveryClient discoveryClient;

    public StatsService(RestTemplate restTemplate, DiscoveryClient discoveryClient) {
        this.restTemplate = restTemplate;
        this.discoveryClient = discoveryClient;
    }

    @CircuitBreaker(name = "playerService", fallbackMethod = "fallbackStats")
    @Retry(name = "playerService")
    public PartyStats getStats(Long partyId) {
        String partyUrl = resolveUrl("party-service");
        String playerUrl = resolveUrl("player-service");

        Map<?, ?> party = restTemplate.getForObject(partyUrl + "/parties/" + partyId, Map.class);
        List<?> players = restTemplate.exchange(
                playerUrl + "/players/party/" + partyId,
                HttpMethod.GET, null,
                new ParameterizedTypeReference<List<?>>() {}
        ).getBody();

        String partyName = party != null ? (String) party.get("name") : "Unknown";
        String gameType = party != null ? (String) party.get("gameType") : "Unknown";
        int playersCount = players != null ? players.size() : 0;

        return new PartyStats(partyName, gameType, playersCount);
    }

    public PartyStats fallbackStats(Long partyId, Throwable t) {
        String partyName = "Unknown";
        String gameType = "Unknown";
        try {
            List<ServiceInstance> instances = discoveryClient.getInstances("party-service");
            if (!instances.isEmpty()) {
                String partyUrl = instances.get(0).getUri().toString();
                Map<?, ?> party = restTemplate.getForObject(partyUrl + "/parties/" + partyId, Map.class);
                if (party != null) {
                    partyName = (String) party.get("name");
                    gameType = (String) party.get("gameType");
                }
            }
        } catch (Exception ignored) {}
        return new PartyStats(partyName, gameType, -1);
    }

    private String resolveUrl(String serviceName) {
        List<ServiceInstance> instances = discoveryClient.getInstances(serviceName);
        if (instances.isEmpty()) {
            throw new RuntimeException("No instances found for " + serviceName);
        }
        return instances.get(0).getUri().toString();
    }
}