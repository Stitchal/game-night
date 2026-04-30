package unica.ds4h.rosset.partyservice.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import unica.ds4h.rosset.partyservice.model.Party;

public interface PartyRepository extends JpaRepository<Party, Long> {
}