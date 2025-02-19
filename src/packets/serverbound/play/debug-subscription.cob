IDENTIFICATION DIVISION.
PROGRAM-ID. RecvPacket-DebugSubscription.

DATA DIVISION.
WORKING-STORAGE SECTION.
    COPY DD-CLIENTS.
    *> payload
    01 SUBSCRIPTION-TYPE        BINARY-LONG.
LINKAGE SECTION.
    01 LK-CLIENT                BINARY-LONG UNSIGNED.
    01 LK-BUFFER                PIC X ANY LENGTH.
    01 LK-OFFSET                BINARY-LONG UNSIGNED.

PROCEDURE DIVISION USING LK-CLIENT LK-BUFFER LK-OFFSET.
    *> TODO limit to operators

    CALL "Decode-VarInt" USING LK-BUFFER LK-OFFSET SUBSCRIPTION-TYPE

    *> 0 = game tick
    IF SUBSCRIPTION-TYPE = 0
        CALL "SystemTimeMicros" USING DEBUG-SUBSCRIBE-TIME(LK-CLIENT)
    END-IF

    GOBACK.

END PROGRAM RecvPacket-DebugSubscription.
