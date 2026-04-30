package unica.ds4h.rosset.partyservice.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import unica.ds4h.rosset.partyservice.model.Party;
import unica.ds4h.rosset.partyservice.service.PartyService;

import java.util.List;

@RestController
@RequestMapping("/parties")
public class PartyController {

    private final PartyService partyService;

    public PartyController(PartyService partyService) {
        this.partyService = partyService;
    }

    @PostMapping
    public ResponseEntity<Party> create(@RequestBody Party party) {
        return ResponseEntity.ok(partyService.create(party));
    }

    @GetMapping
    public ResponseEntity<List<Party>> findAll() {
        return ResponseEntity.ok(partyService.findAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Party> findById(@PathVariable Long id) {
        return partyService.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
}