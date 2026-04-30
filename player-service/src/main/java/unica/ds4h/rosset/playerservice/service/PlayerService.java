package unica.ds4h.rosset.playerservice.service;

import org.springframework.stereotype.Service;
import unica.ds4h.rosset.playerservice.model.Player;
import unica.ds4h.rosset.playerservice.repository.PlayerRepository;

import java.util.List;

@Service
public class PlayerService {

    private final PlayerRepository repository;

    public PlayerService(PlayerRepository repository) {
        this.repository = repository;
    }

    public Player register(Player player) {
        return repository.save(player);
    }

    public List<Player> findByPartyId(Long partyId) {
        return repository.findByPartyId(partyId);
    }
}