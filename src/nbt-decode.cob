*> --- NbtDecode-ReadString ---
IDENTIFICATION DIVISION.
PROGRAM-ID. NbtDecode-ReadString.

DATA DIVISION.
WORKING-STORAGE SECTION.
    01 UINT16           BINARY-SHORT UNSIGNED.
LINKAGE SECTION.
    01 LK-BUFFER        PIC X ANY LENGTH.
    01 LK-OFFSET        BINARY-LONG UNSIGNED.
    01 LK-STRING        PIC X ANY LENGTH.
    01 LK-STRING-LENGTH BINARY-LONG UNSIGNED.

PROCEDURE DIVISION USING LK-BUFFER LK-OFFSET LK-STRING LK-STRING-LENGTH.
    CALL "Decode-UnsignedShort" USING LK-BUFFER LK-OFFSET UINT16
    MOVE UINT16 TO LK-STRING-LENGTH
    MOVE LK-BUFFER(LK-OFFSET:UINT16) TO LK-STRING
    ADD UINT16 TO LK-OFFSET
    GOBACK.

END PROGRAM NbtDecode-ReadString.

*> --- NbtDecode-SkipString ---
IDENTIFICATION DIVISION.
PROGRAM-ID. NbtDecode-SkipString.

DATA DIVISION.
WORKING-STORAGE SECTION.
    01 UINT16           BINARY-SHORT UNSIGNED.
LINKAGE SECTION.
    COPY DD-NBT-DECODER REPLACING LEADING ==NBT-DECODER== BY ==LK==.
    01 LK-BUFFER        PIC X ANY LENGTH.

PROCEDURE DIVISION USING LK-STATE LK-BUFFER.
    CALL "Decode-UnsignedShort" USING LK-BUFFER LK-OFFSET UINT16
    ADD UINT16 TO LK-OFFSET
    GOBACK.

END PROGRAM NbtDecode-SkipString.

*> --- NbtDecode-Byte ---
IDENTIFICATION DIVISION.
PROGRAM-ID. NbtDecode-Byte.

DATA DIVISION.
WORKING-STORAGE SECTION.
    01 INT64            BINARY-LONG-LONG.
LINKAGE SECTION.
    COPY DD-NBT-DECODER REPLACING LEADING ==NBT-DECODER== BY ==LK==.
    01 LK-BUFFER        PIC X ANY LENGTH.
    01 LK-VALUE         BINARY-CHAR.

PROCEDURE DIVISION USING LK-STATE LK-BUFFER LK-VALUE.
    CALL "NbtDecode-Long" USING LK-STATE LK-BUFFER INT64
    MOVE INT64 TO LK-VALUE
    GOBACK.

END PROGRAM NbtDecode-Byte.

*> --- NbtDecode-Int ---
IDENTIFICATION DIVISION.
PROGRAM-ID. NbtDecode-Int.

DATA DIVISION.
WORKING-STORAGE SECTION.
    01 INT64            BINARY-LONG-LONG.
LINKAGE SECTION.
    COPY DD-NBT-DECODER REPLACING LEADING ==NBT-DECODER== BY ==LK==.
    01 LK-BUFFER        PIC X ANY LENGTH.
    01 LK-VALUE         BINARY-LONG.

PROCEDURE DIVISION USING LK-STATE LK-BUFFER LK-VALUE.
    CALL "NbtDecode-Long" USING LK-STATE LK-BUFFER INT64
    MOVE INT64 TO LK-VALUE
    GOBACK.

END PROGRAM NbtDecode-Int.

*> --- NbtDecode-Long ---
IDENTIFICATION DIVISION.
PROGRAM-ID. NbtDecode-Long.

DATA DIVISION.
WORKING-STORAGE SECTION.
    01 TAG              PIC X.
    01 INT8             BINARY-CHAR.
    01 INT16            BINARY-SHORT.
    01 INT32            BINARY-LONG.
LINKAGE SECTION.
    COPY DD-NBT-DECODER REPLACING LEADING ==NBT-DECODER== BY ==LK==.
    01 LK-BUFFER        PIC X ANY LENGTH.
    01 LK-VALUE         BINARY-LONG-LONG.

PROCEDURE DIVISION USING LK-STATE LK-BUFFER LK-VALUE.
    *> Accept any integer type in the NBT data, and return it as a 64-bit signed integer
    IF LK-OFFSET > LENGTH OF LK-BUFFER
        GOBACK
    END-IF

    EVALUATE TRUE
        *> Decoding from a byte array
        WHEN LK-LEVEL > 0 AND LK-STACK-TYPE(LK-LEVEL) = X"07"
            MOVE X"01" TO TAG
        *> Decoding from a list
        WHEN LK-LEVEL > 0 AND LK-STACK-TYPE(LK-LEVEL) = X"09"
            MOVE LK-STACK-LIST-TYPE(LK-LEVEL) TO TAG
        *> Decoding from an int array
        WHEN LK-LEVEL > 0 AND LK-STACK-TYPE(LK-LEVEL) = X"0B"
            MOVE X"03" TO TAG
        *> Decoding from a long array
        WHEN LK-LEVEL > 0 AND LK-STACK-TYPE(LK-LEVEL) = X"0C"
            MOVE X"04" TO TAG
        *> In all other cases, read the tag type from the buffer
        WHEN OTHER
            MOVE LK-BUFFER(LK-OFFSET:1) TO TAG
            ADD 1 TO LK-OFFSET
    END-EVALUATE

    *> If in a compound, skip the name. The caller will have gotten this using NbtDecode-Peek.
    IF LK-LEVEL > 0 AND LK-STACK-TYPE(LK-LEVEL) = X"0A"
        CALL "NbtDecode-SkipString" USING LK-STATE LK-BUFFER
    END-IF

    EVALUATE TAG
        WHEN X"01" *> byte
            CALL "Decode-Byte" USING LK-BUFFER LK-OFFSET INT8
            MOVE INT8 TO LK-VALUE
        WHEN X"02" *> short
            CALL "Decode-Short" USING LK-BUFFER LK-OFFSET INT16
            MOVE INT16 TO LK-VALUE
        WHEN X"03" *> int
            CALL "Decode-Int" USING LK-BUFFER LK-OFFSET INT32
            MOVE INT32 TO LK-VALUE
        WHEN X"04" *> long
            CALL "Decode-Long" USING LK-BUFFER LK-OFFSET LK-VALUE
        WHEN OTHER
            *> TODO handle error
            GOBACK
    END-EVALUATE

    GOBACK.

END PROGRAM NbtDecode-Long.

*> --- NbtDecode-Float ---
IDENTIFICATION DIVISION.
PROGRAM-ID. NbtDecode-Float.

DATA DIVISION.
WORKING-STORAGE SECTION.
    01 TAG              PIC X.
    01 FLOAT32          FLOAT-SHORT.
    01 FLOAT64          FLOAT-LONG.
LINKAGE SECTION.
    COPY DD-NBT-DECODER REPLACING LEADING ==NBT-DECODER== BY ==LK==.
    01 LK-BUFFER        PIC X ANY LENGTH.
    01 LK-VALUE         FLOAT-SHORT.

PROCEDURE DIVISION USING LK-STATE LK-BUFFER LK-VALUE.
    *> Accept any floating-point type in the NBT data, and return it as a 32-bit floating-point number
    IF LK-OFFSET > LENGTH OF LK-BUFFER
        GOBACK
    END-IF

    EVALUATE TRUE
        *> Decoding from a list
        WHEN LK-LEVEL > 0 AND LK-STACK-TYPE(LK-LEVEL) = X"09"
            MOVE LK-STACK-LIST-TYPE(LK-LEVEL) TO TAG
        *> Read the tag type from the buffer
        WHEN OTHER
            MOVE LK-BUFFER(LK-OFFSET:1) TO TAG
            ADD 1 TO LK-OFFSET
    END-EVALUATE

    *> If in a compound, skip the name. The caller will have gotten this using NbtDecode-Peek.
    IF LK-LEVEL > 0 AND LK-STACK-TYPE(LK-LEVEL) = X"0A"
        CALL "NbtDecode-SkipString" USING LK-STATE LK-BUFFER
    END-IF

    EVALUATE TAG
        WHEN X"05" *> float
            CALL "Decode-Float" USING LK-BUFFER LK-OFFSET FLOAT32
            MOVE FLOAT32 TO LK-VALUE
        WHEN X"06" *> double
            CALL "Decode-Double" USING LK-BUFFER LK-OFFSET FLOAT64
            MOVE FLOAT64 TO LK-VALUE
        WHEN OTHER
            *> TODO handle error
            GOBACK
    END-EVALUATE

    GOBACK.

END PROGRAM NbtDecode-Float.

*> --- NbtDecode-Double ---
IDENTIFICATION DIVISION.
PROGRAM-ID. NbtDecode-Double.

DATA DIVISION.
WORKING-STORAGE SECTION.
    01 TAG              PIC X.
    01 FLOAT32          FLOAT-SHORT.
    01 FLOAT64          FLOAT-LONG.
LINKAGE SECTION.
    COPY DD-NBT-DECODER REPLACING LEADING ==NBT-DECODER== BY ==LK==.
    01 LK-BUFFER        PIC X ANY LENGTH.
    01 LK-VALUE         FLOAT-LONG.

PROCEDURE DIVISION USING LK-STATE LK-BUFFER LK-VALUE.
    *> Accept any floating-point type in the NBT data, and return it as a 64-bit floating-point number
    IF LK-OFFSET > LENGTH OF LK-BUFFER
        GOBACK
    END-IF

    EVALUATE TRUE
        *> Decoding from a list
        WHEN LK-LEVEL > 0 AND LK-STACK-TYPE(LK-LEVEL) = X"09"
            MOVE LK-STACK-LIST-TYPE(LK-LEVEL) TO TAG
        *> Read the tag type from the buffer
        WHEN OTHER
            MOVE LK-BUFFER(LK-OFFSET:1) TO TAG
            ADD 1 TO LK-OFFSET
    END-EVALUATE

    *> If in a compound, skip the name. The caller will have gotten this using NbtDecode-Peek.
    IF LK-LEVEL > 0 AND LK-STACK-TYPE(LK-LEVEL) = X"0A"
        CALL "NbtDecode-SkipString" USING LK-STATE LK-BUFFER
    END-IF

    EVALUATE TAG
        WHEN X"05" *> float
            CALL "Decode-Float" USING LK-BUFFER LK-OFFSET FLOAT32
            MOVE FLOAT32 TO LK-VALUE
        WHEN X"06" *> double
            CALL "Decode-Double" USING LK-BUFFER LK-OFFSET FLOAT64
            MOVE FLOAT64 TO LK-VALUE
        WHEN OTHER
            *> TODO handle error
            GOBACK
    END-EVALUATE

    GOBACK.

END PROGRAM NbtDecode-Double.

*> --- NbtDecode-String ---
IDENTIFICATION DIVISION.
PROGRAM-ID. NbtDecode-String.

DATA DIVISION.
WORKING-STORAGE SECTION.
    01 TAG              PIC X.
LINKAGE SECTION.
    COPY DD-NBT-DECODER REPLACING LEADING ==NBT-DECODER== BY ==LK==.
    01 LK-BUFFER        PIC X ANY LENGTH.
    01 LK-STRING-VALUE  PIC X ANY LENGTH.
    01 LK-STRING-LENGTH BINARY-LONG UNSIGNED.

PROCEDURE DIVISION USING LK-STATE LK-BUFFER LK-STRING-VALUE LK-STRING-LENGTH.
    EVALUATE TRUE
        *> This tag is contained in another list, so get its type from the stack
        WHEN LK-LEVEL > 0 AND LK-STACK-TYPE(LK-LEVEL) = X"09"
            MOVE LK-STACK-LIST-TYPE(LK-LEVEL) TO TAG
        *> In all other cases, read the tag type from the buffer
        WHEN OTHER
            MOVE LK-BUFFER(LK-OFFSET:1) TO TAG
            ADD 1 TO LK-OFFSET
    END-EVALUATE

    IF TAG NOT = X"08"
        *> TODO handle error
        GOBACK
    END-IF

    *> If in a compound, skip the name. The caller will have gotten this using NbtDecode-Peek.
    IF LK-LEVEL > 0 AND LK-STACK-TYPE(LK-LEVEL) = X"0A"
        CALL "NbtDecode-SkipString" USING LK-STATE LK-BUFFER
    END-IF

    CALL "NbtDecode-ReadString" USING LK-BUFFER LK-OFFSET LK-STRING-VALUE LK-STRING-LENGTH

    GOBACK.

END PROGRAM NbtDecode-String.

*> --- NbtDecode-List ---
*> Decode a list or array, returning the number of elements.
IDENTIFICATION DIVISION.
PROGRAM-ID. NbtDecode-List.

DATA DIVISION.
WORKING-STORAGE SECTION.
    01 TAG              PIC X.
    01 INT32            BINARY-LONG.
    01 LIST-TAG         PIC X.
LINKAGE SECTION.
    COPY DD-NBT-DECODER REPLACING LEADING ==NBT-DECODER== BY ==LK==.
    01 LK-BUFFER        PIC X ANY LENGTH.
    01 LK-LIST-LENGTH   BINARY-LONG UNSIGNED.

PROCEDURE DIVISION USING LK-STATE LK-BUFFER LK-LIST-LENGTH.
    IF LK-OFFSET > LENGTH OF LK-BUFFER
        GOBACK
    END-IF

    EVALUATE TRUE
        *> This tag is contained in another list, so get its type from the stack
        WHEN LK-LEVEL > 0 AND LK-STACK-TYPE(LK-LEVEL) = X"09"
            MOVE LK-STACK-LIST-TYPE(LK-LEVEL) TO TAG
        *> In all other cases, read the tag type from the buffer
        WHEN OTHER
            MOVE LK-BUFFER(LK-OFFSET:1) TO TAG
            ADD 1 TO LK-OFFSET
    END-EVALUATE

    *> If in a compound, skip the name. The caller will have gotten this using NbtDecode-Peek.
    IF LK-LEVEL > 0 AND LK-STACK-TYPE(LK-LEVEL) = X"0A"
        CALL "NbtDecode-SkipString" USING LK-STATE LK-BUFFER
    END-IF

    *> Determine the type of the list elements
    EVALUATE TAG
        WHEN X"07" *> byte array
            MOVE X"01" TO LIST-TAG
        WHEN X"09" *> list
            MOVE LK-BUFFER(LK-OFFSET:1) TO LIST-TAG
            ADD 1 TO LK-OFFSET
        WHEN X"0B" *> int array
            MOVE X"03" TO LIST-TAG
        WHEN X"0C" *> long array
            MOVE X"04" TO LIST-TAG
        WHEN OTHER
            *> TODO handle error
            GOBACK
    END-EVALUATE

    *> Read the length of the list or array
    CALL "Decode-Int" USING LK-BUFFER LK-OFFSET INT32
    IF INT32 <= 0
        MOVE 0 TO LK-LIST-LENGTH
    ELSE
        MOVE INT32 TO LK-LIST-LENGTH
    END-IF

    *> Push the container onto the stack
    ADD 1 TO LK-LEVEL
    MOVE TAG TO LK-STACK-TYPE(LK-LEVEL)
    MOVE LIST-TAG TO LK-STACK-LIST-TYPE(LK-LEVEL)
    MOVE LK-LIST-LENGTH TO LK-STACK-LIST-COUNT(LK-LEVEL)

    GOBACK.

END PROGRAM NbtDecode-List.

*> --- NbtDecode-EndList ---
IDENTIFICATION DIVISION.
PROGRAM-ID. NbtDecode-EndList.

DATA DIVISION.
LINKAGE SECTION.
    COPY DD-NBT-DECODER REPLACING LEADING ==NBT-DECODER== BY ==LK==.
    01 LK-BUFFER        PIC X ANY LENGTH.

PROCEDURE DIVISION USING LK-STATE LK-BUFFER.
    IF LK-LEVEL < 1 OR LK-STACK-TYPE(LK-LEVEL) = X"0A"
        DISPLAY "ERROR: EndList called without a matching list or array"
        STOP RUN RETURNING 1
    END-IF
    *> Pop the stack
    SUBTRACT 1 FROM LK-LEVEL
    GOBACK.

END PROGRAM NbtDecode-EndList.

*> --- NbtDecode-ByteBuffer ---
*> A utility subroutine to read a byte array with contents directly into a buffer.
IDENTIFICATION DIVISION.
PROGRAM-ID. NbtDecode-ByteBuffer.

DATA DIVISION.
LINKAGE SECTION.
    COPY DD-NBT-DECODER REPLACING LEADING ==NBT-DECODER== BY ==LK==.
    01 LK-BUFFER        PIC X ANY LENGTH.
    01 LK-DATA          PIC X ANY LENGTH.
    01 LK-DATA-LENGTH   BINARY-LONG UNSIGNED.

PROCEDURE DIVISION USING LK-STATE LK-BUFFER LK-DATA LK-DATA-LENGTH.
    CALL "NbtDecode-List" USING LK-STATE LK-BUFFER LK-DATA-LENGTH
    IF LK-DATA-LENGTH > LENGTH OF LK-DATA
        *> TODO handle error
        GOBACK
    END-IF
    IF (LK-STACK-TYPE(LK-LEVEL) = X"09" AND LK-STACK-LIST-TYPE(LK-LEVEL) = X"01") OR LK-STACK-TYPE(LK-LEVEL) = X"07"
        MOVE LK-BUFFER(LK-OFFSET:LK-DATA-LENGTH) TO LK-DATA
        ADD LK-DATA-LENGTH TO LK-OFFSET
    ELSE
        *> TODO handle error
        GOBACK
    END-IF
    CALL "NbtDecode-EndList" USING LK-STATE LK-BUFFER
    GOBACK.

END PROGRAM NbtDecode-ByteBuffer.

*> --- NbtDecode-Compound ---
IDENTIFICATION DIVISION.
PROGRAM-ID. NbtDecode-Compound.

DATA DIVISION.
WORKING-STORAGE SECTION.
    01 TAG              PIC X.
LINKAGE SECTION.
    COPY DD-NBT-DECODER REPLACING LEADING ==NBT-DECODER== BY ==LK==.
    01 LK-BUFFER        PIC X ANY LENGTH.

PROCEDURE DIVISION USING LK-STATE LK-BUFFER.
    EVALUATE TRUE
        *> If this tag is contained in a list, get its type from the stack
        WHEN LK-LEVEL > 0 AND LK-STACK-TYPE(LK-LEVEL) = X"09"
            MOVE LK-STACK-LIST-TYPE(LK-LEVEL) TO TAG
        *> In all other cases, read the tag type from the buffer
        WHEN OTHER
            MOVE LK-BUFFER(LK-OFFSET:1) TO TAG
            ADD 1 TO LK-OFFSET
    END-EVALUATE

    IF TAG NOT = X"0A"
        *> TODO handle error
        GOBACK
    END-IF

    *> If in a compound, skip the name
    IF LK-LEVEL > 0 AND LK-STACK-TYPE(LK-LEVEL) = X"0A"
        CALL "NbtDecode-SkipString" USING LK-STATE LK-BUFFER
    END-IF

    *> Push the compound onto the stack
    ADD 1 TO LK-LEVEL
    MOVE X"0A" TO LK-STACK-TYPE(LK-LEVEL)

    GOBACK.

END PROGRAM NbtDecode-Compound.

*> --- NbtDecode-RootCompound ---
IDENTIFICATION DIVISION.
PROGRAM-ID. NbtDecode-RootCompound.

DATA DIVISION.
WORKING-STORAGE SECTION.
    01 TAG-EXTENT       BINARY-LONG UNSIGNED.
LINKAGE SECTION.
    COPY DD-NBT-DECODER REPLACING LEADING ==NBT-DECODER== BY ==LK==.
    01 LK-BUFFER        PIC X ANY LENGTH.

PROCEDURE DIVISION USING LK-STATE LK-BUFFER.
    *> The root compound is special because it always has a name (the empty string) even without any wrapping compound.
    *> Since networking code does not use a name for root-level compounds, this needs to be a separate subroutine.
    COMPUTE TAG-EXTENT = LK-OFFSET + 2
    IF TAG-EXTENT > LENGTH OF LK-BUFFER OR LK-BUFFER(LK-OFFSET:1) NOT = X"0A"
        *> TODO handle error
        GOBACK
    END-IF
    ADD 1 TO LK-OFFSET
    IF LK-BUFFER(LK-OFFSET:1) NOT = X"00" OR LK-BUFFER(LK-OFFSET + 1:1) NOT = X"00"
        *> TODO handle error
        GOBACK
    END-IF
    ADD 2 TO LK-OFFSET
    *> Push the compound onto the stack
    ADD 1 TO LK-LEVEL
    MOVE X"0A" TO LK-STACK-TYPE(LK-LEVEL)
    GOBACK.

END PROGRAM NbtDecode-RootCompound.

*> --- NbtDecode-EndCompound ---
IDENTIFICATION DIVISION.
PROGRAM-ID. NbtDecode-EndCompound.

DATA DIVISION.
LINKAGE SECTION.
    COPY DD-NBT-DECODER REPLACING LEADING ==NBT-DECODER== BY ==LK==.
    01 LK-BUFFER        PIC X ANY LENGTH.

PROCEDURE DIVISION USING LK-STATE LK-BUFFER.
    IF LK-LEVEL < 1 OR LK-STACK-TYPE(LK-LEVEL) NOT = X"0A"
        DISPLAY "ERROR: EndCompound called without a matching Compound"
        STOP RUN RETURNING 1
    END-IF

    IF LK-OFFSET > LENGTH OF LK-BUFFER OR LK-BUFFER(LK-OFFSET:1) NOT = X"00"
        *> TODO handle error
        GOBACK
    END-IF
    ADD 1 TO LK-OFFSET

    *> Pop the stack
    SUBTRACT 1 FROM LK-LEVEL

    GOBACK.

END PROGRAM NbtDecode-EndCompound.

*> --- NbtDecode-Peek ---
*> Peek at the name of the next tag in the buffer, without advancing the offset.
*> In case the end tag is reached, a flag is set to indicate this.
IDENTIFICATION DIVISION.
PROGRAM-ID. NbtDecode-Peek.

DATA DIVISION.
WORKING-STORAGE SECTION.
    01 NAME-OFFSET      BINARY-LONG UNSIGNED.
LINKAGE SECTION.
    COPY DD-NBT-DECODER REPLACING LEADING ==NBT-DECODER== BY ==LK==.
    01 LK-BUFFER        PIC X ANY LENGTH.
    01 LK-AT-END        BINARY-CHAR UNSIGNED.
    01 LK-NAME          PIC X ANY LENGTH.
    01 LK-NAME-LENGTH   BINARY-LONG UNSIGNED.

PROCEDURE DIVISION USING LK-STATE LK-BUFFER LK-AT-END LK-NAME LK-NAME-LENGTH.
    IF LK-OFFSET <= LENGTH OF LK-BUFFER AND LK-BUFFER(LK-OFFSET:1) = X"00"
        MOVE 1 TO LK-AT-END
        MOVE 0 TO LK-NAME-LENGTH
        GOBACK
    END-IF
    MOVE 0 TO LK-AT-END
    COMPUTE NAME-OFFSET = LK-OFFSET + 1
    CALL "NbtDecode-ReadString" USING LK-BUFFER NAME-OFFSET LK-NAME LK-NAME-LENGTH
    GOBACK.

END PROGRAM NbtDecode-Peek.

*> --- NbtDecode-Skip ---
IDENTIFICATION DIVISION.
PROGRAM-ID. NbtDecode-Skip IS RECURSIVE.

DATA DIVISION.
WORKING-STORAGE SECTION.
    01 TAG              PIC X.
LINKAGE SECTION.
    COPY DD-NBT-DECODER REPLACING LEADING ==NBT-DECODER== BY ==LK==.
    01 LK-BUFFER        PIC X ANY LENGTH.

PROCEDURE DIVISION USING LK-STATE LK-BUFFER.
    IF LK-OFFSET > LENGTH OF LK-BUFFER
        GOBACK
    END-IF

    *> Determine the tag type based on the container, or read it from the buffer.
    IF LK-LEVEL > 0
        EVALUATE LK-STACK-TYPE(LK-LEVEL)
            *> Byte arrays have fixed type 0x01 (byte)
            WHEN X"07"
                MOVE X"01" TO TAG
            *> Lists store the type in their stack entry
            WHEN X"09"
                MOVE LK-STACK-LIST-TYPE(LK-LEVEL) TO TAG
            *> Int arrays have fixed type 0x03 (int)
            WHEN X"0B"
                MOVE X"03" TO TAG
            *> Long arrays have fixed type 0x04 (long)
            WHEN X"0C"
                MOVE X"04" TO TAG
            *> We must be in a compound, so read the tag type from the buffer
            WHEN OTHER
                MOVE LK-BUFFER(LK-OFFSET:1) TO TAG
                ADD 1 TO LK-OFFSET
                *> Skip the tag name
                IF LK-LEVEL > 0 AND LK-STACK-TYPE(LK-LEVEL) = X"0A"
                    CALL "NbtDecode-SkipString" USING LK-STATE LK-BUFFER
                END-IF
        END-EVALUATE
    ELSE
        *> Read the tag type without a name
        MOVE LK-BUFFER(LK-OFFSET:1) TO TAG
        ADD 1 TO LK-OFFSET
    END-IF

    *> Skip the value
    CALL "NbtDecode-SkipValue" USING LK-STATE LK-BUFFER TAG

    GOBACK.

END PROGRAM NbtDecode-Skip.

*> --- NbtDecode-SkipValue ---
*> Skip just the value of the current tag, where the tag type has already been read.
IDENTIFICATION DIVISION.
PROGRAM-ID. NbtDecode-SkipValue IS RECURSIVE.

DATA DIVISION.
LOCAL-STORAGE SECTION.
    01 INT32            BINARY-LONG.
    01 LIST-TAG         PIC X.
LINKAGE SECTION.
    COPY DD-NBT-DECODER REPLACING LEADING ==NBT-DECODER== BY ==LK==.
    01 LK-BUFFER        PIC X ANY LENGTH.
    01 LK-TAG           PIC X.

PROCEDURE DIVISION USING LK-STATE LK-BUFFER LK-TAG.
    EVALUATE LK-TAG
        WHEN X"00" *> end
            *> Pop the stack
            SUBTRACT 1 FROM LK-LEVEL
            CONTINUE

        WHEN X"01" *> byte
            ADD 1 TO LK-OFFSET

        WHEN X"02" *> short
            ADD 2 TO LK-OFFSET

        WHEN X"03" *> int
            ADD 4 TO LK-OFFSET

        WHEN X"04" *> long
            ADD 8 TO LK-OFFSET

        WHEN X"05" *> float
            ADD 4 TO LK-OFFSET

        WHEN X"06" *> double
            ADD 8 TO LK-OFFSET

        WHEN X"07" *> byte array
            *> Read the length, and skip as many bytes
            CALL "Decode-Int" USING LK-BUFFER LK-OFFSET INT32
            IF INT32 > 0
                ADD INT32 TO LK-OFFSET
            END-IF

        WHEN X"08" *> string
            CALL "NbtDecode-SkipString" USING LK-STATE LK-BUFFER

        WHEN X"09" *> list
            *> The first byte of the list is the type of the elements, followed by the length as an int
            MOVE LK-BUFFER(LK-OFFSET:1) TO LIST-TAG
            ADD 1 TO LK-OFFSET
            CALL "Decode-Int" USING LK-BUFFER LK-OFFSET INT32
            IF INT32 <= 0 OR LIST-TAG = X"00"
                GOBACK
            END-IF

            *> Push the list onto the stack
            ADD 1 TO LK-LEVEL
            MOVE LK-TAG TO LK-STACK-TYPE(LK-LEVEL)
            MOVE LIST-TAG TO LK-STACK-LIST-TYPE(LK-LEVEL)
            MOVE INT32 TO LK-STACK-LIST-COUNT(LK-LEVEL)

            *> Skip the elements
            PERFORM INT32 TIMES
                CALL "NbtDecode-SkipValue" USING LK-STATE LK-BUFFER LIST-TAG
            END-PERFORM

            *> Pop the stack
            SUBTRACT 1 FROM LK-LEVEL

        WHEN X"0A" *> compound
            ADD 1 TO LK-LEVEL
            MOVE LK-TAG TO LK-STACK-TYPE(LK-LEVEL)
            PERFORM UNTIL LK-BUFFER(LK-OFFSET:1) = X"00"
                CALL "NbtDecode-Skip" USING LK-STATE LK-BUFFER
            END-PERFORM
            CALL "NbtDecode-EndCompound" USING LK-STATE LK-BUFFER

        WHEN X"0B" *> int array
            *> Read the length, and skip as many ints
            CALL "Decode-Int" USING LK-BUFFER LK-OFFSET INT32
            IF INT32 > 0
                COMPUTE LK-OFFSET = LK-OFFSET + INT32 * 4
            END-IF

        WHEN X"0C" *> long array
            *> Read the length, and skip as many longs
            CALL "Decode-Int" USING LK-BUFFER LK-OFFSET INT32
            IF INT32 > 0
                COMPUTE LK-OFFSET = LK-OFFSET + INT32 * 8
            END-IF

        WHEN OTHER
            *> TODO handle error
            GOBACK
    END-EVALUATE

    GOBACK.

END PROGRAM NbtDecode-SkipValue.

*> --- NbtDecode-UUID ---
*> While there is no NBT tag for UUIDs, they are commonly stored as an array of 4 integers, for which this subroutine
*> is provided.
IDENTIFICATION DIVISION.
PROGRAM-ID. NbtDecode-UUID.

DATA DIVISION.
WORKING-STORAGE SECTION.
    01 INT-COUNT        BINARY-LONG UNSIGNED.
    01 UUID-OFFSET      BINARY-LONG UNSIGNED.
    01 INT32-BYTES.
        02 INT32        BINARY-LONG.
LINKAGE SECTION.
    COPY DD-NBT-DECODER REPLACING LEADING ==NBT-DECODER== BY ==LK==.
    01 LK-BUFFER        PIC X ANY LENGTH.
    01 LK-UUID          PIC X(16).

PROCEDURE DIVISION USING LK-STATE LK-BUFFER LK-UUID.
    CALL "NbtDecode-List" USING LK-STATE LK-BUFFER INT-COUNT

    IF INT-COUNT NOT = 4
        MOVE ALL X"00" TO LK-UUID
        PERFORM INT-COUNT TIMES
            CALL "NbtDecode-Int" USING LK-STATE LK-BUFFER INT32
        END-PERFORM
    ELSE
        PERFORM VARYING UUID-OFFSET FROM 1 BY 4 UNTIL UUID-OFFSET > 16
            CALL "NbtDecode-Int" USING LK-STATE LK-BUFFER INT32
            MOVE FUNCTION REVERSE(INT32-BYTES) TO LK-UUID(UUID-OFFSET:4)
        END-PERFORM
    END-IF

    CALL "NbtDecode-EndList" USING LK-STATE LK-BUFFER

    GOBACK.

END PROGRAM NbtDecode-UUID.

*> --- NbtDecode-SkipUntilTag ---
*> A utility procedure to skip until a tag with a given name is found. If found, the offset will be set to the
*> start of the tag. Otherwise, the offset will be at the end of the compound, and the "at end" flag will be set.
IDENTIFICATION DIVISION.
PROGRAM-ID. NbtDecode-SkipUntilTag.

DATA DIVISION.
WORKING-STORAGE SECTION.
    01 TAG-NAME             PIC X(256).
    01 NAME-LEN             BINARY-LONG UNSIGNED.
LINKAGE SECTION.
    COPY DD-NBT-DECODER REPLACING LEADING ==NBT-DECODER== BY ==LK==.
    01 LK-BUFFER            PIC X ANY LENGTH.
    01 LK-TAG-NAME          PIC X ANY LENGTH.
    01 LK-AT-END            BINARY-CHAR UNSIGNED.

PROCEDURE DIVISION USING LK-STATE LK-BUFFER LK-TAG-NAME LK-AT-END.
    PERFORM UNTIL EXIT
        CALL "NbtDecode-Peek" USING LK-STATE LK-BUFFER LK-AT-END TAG-NAME NAME-LEN
        IF LK-AT-END > 0
            GOBACK
        END-IF
        IF TAG-NAME(1:NAME-LEN) = LK-TAG-NAME
            EXIT PERFORM
        END-IF
        CALL "NbtDecode-Skip" USING LK-STATE LK-BUFFER
    END-PERFORM
    MOVE 0 TO LK-AT-END
    GOBACK.

END PROGRAM NbtDecode-SkipUntilTag.

*> --- NbtDecode-SkipRemainingTags ---
*> A utility procedure to skip all remaining tags in a compound.
IDENTIFICATION DIVISION.
PROGRAM-ID. NbtDecode-SkipRemainingTags.

DATA DIVISION.
WORKING-STORAGE SECTION.
    01 AT-END               BINARY-CHAR UNSIGNED.
    01 TAG-NAME             PIC X(256).
    01 NAME-LEN             BINARY-LONG UNSIGNED.
LINKAGE SECTION.
    COPY DD-NBT-DECODER REPLACING LEADING ==NBT-DECODER== BY ==LK==.
    01 LK-BUFFER            PIC X ANY LENGTH.

PROCEDURE DIVISION USING LK-STATE LK-BUFFER.
    PERFORM UNTIL EXIT
        CALL "NbtDecode-Peek" USING LK-STATE LK-BUFFER AT-END TAG-NAME NAME-LEN
        IF AT-END > 0
            GOBACK
        END-IF
        CALL "NbtDecode-Skip" USING LK-STATE LK-BUFFER
    END-PERFORM
    GOBACK.

END PROGRAM NbtDecode-SkipRemainingTags.
