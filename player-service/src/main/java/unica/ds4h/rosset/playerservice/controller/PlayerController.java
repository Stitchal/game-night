package unica.ds4h.rosset.playerservice.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import unica.ds4h.rosset.playerservice.model.Player;
import unica.ds4h.rosset.playerservice.service.PlayerService;

import java.util.List;

@RestController
@RequestMapping("/players")
public class PlayerController {

    private final PlayerService playerService;

    public PlayerController(PlayerService playerService) {
        this.playerService = playerService;
    }

    @PostMapping
    public ResponseEntity<Player> register(@RequestBody Player player) {
        return ResponseEntity.ok(playerService.register(player));
    }

    @GetMapping("/party/{partyId}")
    public ResponseEntity<List<Player>> findByParty(@PathVariable Long partyId) {
        return ResponseEntity.ok(playerService.findByPartyId(partyId));
    }
}