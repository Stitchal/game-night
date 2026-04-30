package unica.ds4h.rosset.playerservice.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import unica.ds4h.rosset.playerservice.model.Player;

import java.util.List;

public interface PlayerRepository extends JpaRepository<Player, Long> {
    List<Player> findByPartyId(Long partyId);
}