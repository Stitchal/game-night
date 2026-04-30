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
        try {
            String partyUrl = resolveUrl("party-service");
            Map<?, ?> party = restTemplate.getForObject(partyUrl + "/parties/" + partyId, Map.class);
            String partyName = party != null ? (String) party.get("name") : "Unknown";
            String gameType = party != null ? (String) party.get("gameType") : "Unknown";
            return new PartyStats(partyName, gameType, -1);
        } catch (Exception e) {
            return new PartyStats("Unknown", "Unknown", -1);
        }
    }

    private String resolveUrl(String serviceName) {
        List<ServiceInstance> instances = discoveryClient.getInstances(serviceName);
        if (instances.isEmpty()) {
            throw new IllegalStateException("No instances found for " + serviceName);
        }
        return instances.get(0).getUri().toString();
    }
}