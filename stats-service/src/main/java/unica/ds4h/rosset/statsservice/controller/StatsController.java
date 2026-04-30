package unica.ds4h.rosset.statsservice.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import unica.ds4h.rosset.statsservice.model.PartyStats;
import unica.ds4h.rosset.statsservice.service.StatsService;

@RestController
@RequestMapping("/stats")
public class StatsController {

    private final StatsService statsService;

    public StatsController(StatsService statsService) {
        this.statsService = statsService;
    }

    @GetMapping("/{partyId}")
    public ResponseEntity<PartyStats> getStats(@PathVariable Long partyId) {
        return ResponseEntity.ok(statsService.getStats(partyId));
    }
}