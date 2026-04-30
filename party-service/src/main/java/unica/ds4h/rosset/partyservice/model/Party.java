package unica.ds4h.rosset.partyservice.model;

import jakarta.persistence.*;
import java.time.LocalDate;

@Entity
@Table(name = "parties")
public class Party {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;
    private String gameType;
    private LocalDate date;

    public Party() {}

    public Party(String name, String gameType, LocalDate date) {
        this.name = name;
        this.gameType = gameType;
        this.date = date;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getGameType() { return gameType; }
    public void setGameType(String gameType) { this.gameType = gameType; }

    public LocalDate getDate() { return date; }
    public void setDate(LocalDate date) { this.date = date; }
}