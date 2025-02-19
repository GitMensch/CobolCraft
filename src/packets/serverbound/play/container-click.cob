IDENTIFICATION DIVISION.
PROGRAM-ID. RecvPacket-ContainerClick.

DATA DIVISION.
WORKING-STORAGE SECTION.
    COPY DD-CLIENTS.
    COPY DD-PLAYERS.
    01 PLAYER-ID                BINARY-LONG.
    01 WINDOW-ID                BINARY-LONG.
    01 STATE-ID                 BINARY-LONG.
    01 SLOT                     BINARY-SHORT.
    01 BUTTON                   BINARY-CHAR.
    01 MODE-ENUM                BINARY-LONG.
    01 CHANGED-SLOT-COUNT       BINARY-LONG.
    01 SLOT-NUMBER              BINARY-SHORT.
    01 DECODE-SLOT-COUNT        BINARY-CHAR.
    01 CLIENT-SLOT.
        COPY DD-INVENTORY-SLOT REPLACING LEADING ==PREFIX== BY ==CLIENT==.
    01 COMPONENTS-OFFSET        BINARY-LONG UNSIGNED.
    01 COMPONENTS-ADD-COUNT     BINARY-LONG.
    01 COMPONENTS-REMOVE-COUNT  BINARY-LONG.
    01 COMPONENTS-LENGTH        BINARY-LONG UNSIGNED.
    01 COMPONENT-ID             BINARY-LONG.
LINKAGE SECTION.
    01 LK-CLIENT                BINARY-LONG UNSIGNED.
    01 LK-BUFFER                PIC X ANY LENGTH.
    01 LK-OFFSET                BINARY-LONG UNSIGNED.

PROCEDURE DIVISION USING LK-CLIENT LK-BUFFER LK-OFFSET.
    MOVE CLIENT-PLAYER(LK-CLIENT) TO PLAYER-ID

    CALL "Decode-VarInt" USING LK-BUFFER LK-OFFSET WINDOW-ID
    CALL "Decode-VarInt" USING LK-BUFFER LK-OFFSET STATE-ID
    CALL "Decode-Short" USING LK-BUFFER LK-OFFSET SLOT
    CALL "Decode-Byte" USING LK-BUFFER LK-OFFSET BUTTON
    CALL "Decode-VarInt" USING LK-BUFFER LK-OFFSET MODE-ENUM

    *> TODO We currently accept the client's changed slot data as correct, but we should really compute it ourselves
    *>      based on slot/button/mode and then check if it matches the client's data.

    *> TOOD implement containers other than inventory
    IF WINDOW-ID NOT = 0
        PERFORM SyncInventory
        GOBACK
    END-IF

    *> sync client if state ID differs from last sent
    IF STATE-ID NOT = PLAYER-WINDOW-STATE(PLAYER-ID)
        PERFORM SyncInventory
        GOBACK
    END-IF

    *> TODO support dropping items
    IF (MODE-ENUM = 0 AND SLOT = -999) OR (MODE-ENUM = 4)
        PERFORM SyncInventory
        GOBACK
    END-IF

    *> iterate changed slots
    CALL "Decode-VarInt" USING LK-BUFFER LK-OFFSET CHANGED-SLOT-COUNT
    IF CHANGED-SLOT-COUNT <= 0 OR CHANGED-SLOT-COUNT > 128
        GOBACK
    END-IF
    PERFORM CHANGED-SLOT-COUNT TIMES
        CALL "Decode-Short" USING LK-BUFFER LK-OFFSET SLOT-NUMBER
        PERFORM DecodeSlot
        IF SLOT-NUMBER >= 0 AND SLOT-NUMBER < 46
            MOVE CLIENT-SLOT TO PLAYER-INVENTORY-SLOT(PLAYER-ID, SLOT-NUMBER + 1)
        ELSE
            DISPLAY "Invalid slot number: " SLOT-NUMBER
        END-IF
    END-PERFORM

    *> carried item
    PERFORM DecodeSlot
    MOVE CLIENT-SLOT TO PLAYER-MOUSE-ITEM(PLAYER-ID)

    GOBACK.

SyncInventory.
    ADD 1 TO PLAYER-WINDOW-STATE(PLAYER-ID)
    CALL "SendPacket-SetContainerContent" USING LK-CLIENT PLAYER-WINDOW-STATE(PLAYER-ID)
        PLAYER-INVENTORY(PLAYER-ID) PLAYER-MOUSE-ITEM(PLAYER-ID)
    EXIT PARAGRAPH.

DecodeSlot.
    *> TODO deduplicate slot decoding with "set creative slot" packet

    *> count
    CALL "Decode-Byte" USING LK-BUFFER LK-OFFSET DECODE-SLOT-COUNT
    MOVE DECODE-SLOT-COUNT TO CLIENT-SLOT-COUNT

    IF DECODE-SLOT-COUNT = 0
        MOVE 0 TO CLIENT-SLOT-ID
    ELSE
        *> id
        CALL "Decode-VarInt" USING LK-BUFFER LK-OFFSET CLIENT-SLOT-ID

        *> components
        MOVE LK-OFFSET TO COMPONENTS-OFFSET
        CALL "Decode-VarInt" USING LK-BUFFER COMPONENTS-OFFSET COMPONENTS-ADD-COUNT
        CALL "Decode-VarInt" USING LK-BUFFER COMPONENTS-OFFSET COMPONENTS-REMOVE-COUNT
        PERFORM COMPONENTS-ADD-COUNT TIMES
            CALL "Components-LengthOf" USING LK-BUFFER COMPONENTS-OFFSET COMPONENTS-LENGTH
            ADD COMPONENTS-LENGTH TO COMPONENTS-OFFSET
        END-PERFORM
        PERFORM COMPONENTS-REMOVE-COUNT TIMES
            CALL "Decode-VarInt" USING LK-BUFFER COMPONENTS-OFFSET COMPONENT-ID
        END-PERFORM

        COMPUTE CLIENT-SLOT-NBT-LENGTH = COMPONENTS-OFFSET - LK-OFFSET
        IF CLIENT-SLOT-NBT-LENGTH <= 1024
            MOVE LK-BUFFER(LK-OFFSET:CLIENT-SLOT-NBT-LENGTH) TO CLIENT-SLOT-NBT-DATA(1:CLIENT-SLOT-NBT-LENGTH)
        ELSE
            MOVE 0 TO CLIENT-SLOT-NBT-LENGTH
            DISPLAY "Item NBT data too long: " CLIENT-SLOT-NBT-LENGTH
        END-IF

        MOVE COMPONENTS-OFFSET TO LK-OFFSET
    END-IF

    EXIT PARAGRAPH.

END PROGRAM RecvPacket-ContainerClick.
