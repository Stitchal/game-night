package unica.ds4h.rosset.statsservice.model;

public class PartyStats {

    private String partyName;
    private String gameType;
    private int playersCount;

    public PartyStats(String partyName, String gameType, int playersCount) {
        this.partyName = partyName;
        this.gameType = gameType;
        this.playersCount = playersCount;
    }

    public String getPartyName() { return partyName; }
    public void setPartyName(String partyName) { this.partyName = partyName; }

    public String getGameType() { return gameType; }
    public void setGameType(String gameType) { this.gameType = gameType; }

    public int getPlayersCount() { return playersCount; }
    public void setPlayersCount(int playersCount) { this.playersCount = playersCount; }
}