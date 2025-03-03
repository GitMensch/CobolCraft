*> --- RegisterEntity-Generic ---
IDENTIFICATION DIVISION.
PROGRAM-ID. RegisterEntity-Generic.

DATA DIVISION.
WORKING-STORAGE SECTION.
    01 SERIALIZE-PTR            PROGRAM-POINTER.
    01 DESERIALIZE-PTR          PROGRAM-POINTER.
    01 TICK-PTR                 PROGRAM-POINTER.
    01 REGISTRY-INDEX           BINARY-LONG UNSIGNED.
    01 REGISTRY-LENGTH          BINARY-LONG UNSIGNED.
    01 REGISTRY-ENTRY-INDEX     BINARY-LONG UNSIGNED.
    01 REGISTRY-ENTRY-ID        BINARY-LONG UNSIGNED.

PROCEDURE DIVISION.
    SET SERIALIZE-PTR TO ENTRY "EntityBase-Serialize"
    SET DESERIALIZE-PTR TO ENTRY "EntityBase-Deserialize"
    SET TICK-PTR TO ENTRY "Callback-Tick"

    CALL "Registries-GetRegistryIndex" USING "minecraft:entity_type" REGISTRY-INDEX
    COPY ASSERT REPLACING COND BY ==REGISTRY-INDEX > 0==,
        MSG BY =="RegisterEntity-Generic: Missing entity type registry"==.

    CALL "Registries-GetRegistryLength" USING REGISTRY-INDEX REGISTRY-LENGTH
    PERFORM VARYING REGISTRY-ENTRY-INDEX FROM 1 BY 1 UNTIL REGISTRY-ENTRY-INDEX > REGISTRY-LENGTH
        CALL "Registries-Iterate-EntryId" USING REGISTRY-INDEX REGISTRY-ENTRY-INDEX REGISTRY-ENTRY-ID
        CALL "SetCallback-EntitySerialize" USING REGISTRY-ENTRY-ID SERIALIZE-PTR
        CALL "SetCallback-EntityDeserialize" USING REGISTRY-ENTRY-ID DESERIALIZE-PTR
        CALL "SetCallback-EntityTick" USING REGISTRY-ENTRY-ID TICK-PTR
    END-PERFORM

    GOBACK.

    *> --- Callback-Tick ---
    IDENTIFICATION DIVISION.
    PROGRAM-ID. Callback-Tick.

    DATA DIVISION.
    LINKAGE SECTION.
        COPY DD-CALLBACK-ENTITY-TICK.

    PROCEDURE DIVISION USING LK-ENTITY LK-PLAYER-AABBS LK-REMOVE.
        MOVE 0 TO LK-REMOVE
        GOBACK.

    END PROGRAM Callback-Tick.

END PROGRAM RegisterEntity-Generic.
