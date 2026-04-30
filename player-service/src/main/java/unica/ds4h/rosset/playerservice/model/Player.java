package unica.ds4h.rosset.playerservice.model;

import jakarta.persistence.*;

@Entity
@Table(name = "players")
public class Player {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long partyId;
    private String playerName;

    public Player() {}

    public Player(Long partyId, String playerName) {
        this.partyId = partyId;
        this.playerName = playerName;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getPartyId() { return partyId; }
    public void setPartyId(Long partyId) { this.partyId = partyId; }

    public String getPlayerName() { return playerName; }
    public void setPlayerName(String playerName) { this.playerName = playerName; }
}