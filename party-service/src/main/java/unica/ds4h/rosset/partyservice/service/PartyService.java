package unica.ds4h.rosset.partyservice.service;

import org.springframework.stereotype.Service;
import unica.ds4h.rosset.partyservice.model.Party;
import unica.ds4h.rosset.partyservice.repository.PartyRepository;

import java.util.List;
import java.util.Optional;

@Service
public class PartyService {

    private final PartyRepository repository;

    public PartyService(PartyRepository repository) {
        this.repository = repository;
    }

    public Party create(Party party) {
        return repository.save(party);
    }

    public List<Party> findAll() {
        return repository.findAll();
    }

    public Optional<Party> findById(Long id) {
        return repository.findById(id);
    }
}