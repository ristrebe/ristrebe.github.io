USE [Bibliothek]
GO

DROP PROCEDURE IF EXISTS [dbo].[sp_Rueckgabe]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ===========================================================================================    
-- Author:		project group (four members) for final assignment of a module on relational
--              databases and SQL programming

-- Create date: 27.05.2020

-- Description:	procedure for reversal of an item in a library database
--              SQL Code for MS SQL Server

--              input parameters: 
--              - barcode of the items that should be reversed
--              - library card number

--              output parameter:
--              - @feedback  feedback of the system or error message
--              - @erfolg    either 0: process cancelled
--                           or 1: item has been reversed

--              several test processes are connected to the reversal (TRY CATCH), that 
--              might prompt different kinds of feedback (item was reversed nevertheless)
--              or error messages (process was interrupted):
--              - existence or barcode (else error message)
-- 			    - correct status of the item (else feedback)
--              - item correctly noted as lent by the library user (else error message)
--              - check on delayed return and calculation of the overdue fine (feedback)
          
--              If no test process leads to an error message, the item is reversed and
--              the status of the item is set on 'available'.
         
-- ============================================================================================

CREATE PROCEDURE [dbo].[sp_Rueckgabe]

    -- definition of input and output parameters
    @Barcode bigint, 
	@Ausweisnummer bigint,
	@feedback nvarchar(MAX) OUTPUT,
	@erfolg bit OUTPUT

	
AS
BEGIN
	
	SET NOCOUNT ON;

	-- required variables
	DECLARE @AusleiheKunde table (ID int, KundenID int, 
				  MediumID int, Ausleihdatum date,
				  Faelligkeit date, Rueckgabedatum date);
	DECLARE @MahnGebuehr money;
	DECLARE @Ausleihdatum date;
	DECLARE @faelligkeit date;
	DECLARE @OverDay int;
	DECLARE @MediumID int;
	DECLARE @mediumStatus nvarchar(30);
	DECLARE @Rueckgabedatum date;
	DECLARE @AusleihID int;


	BEGIN TRY 
	    SET @erfolg = 1;
		SET @feedback = 'Medium wurde zurückgebucht';
		SET @Rueckgabedatum = GETDATE();
		
		-- creation of an unambiguous entry in table @AusleiheKunde from barcode, library card number and 
        -- reversal date IS NULL. Thus it is possible in the following process to easily access further data 
        -- from this entry.

		INSERT INTO @AusleiheKunde 
			SELECT	Ausleihen.ID, 
					Ausleihen.KundenID, 
					Ausleihen.MediumID, 
					Ausleihen.Ausleihdatum, 
					Ausleihen.Faelligkeit, 
					Ausleihen.Rueckgabedatum
			FROM Ausleihen 
					INNER JOIN Bestand ON Ausleihen.MediumID = Bestand.ID 
					INNER JOIN Kunden ON Kunden.ID = Ausleihen.KundenID
			WHERE @Barcode = Bestand.Barcodenummer AND @Ausweisnummer = Kunden.Ausweisnummer 
								AND Ausleihen.Rueckgabedatum IS NULL ;

		
		-- check if barcode exists
		SELECT @MediumID = Bestand.ID  FROM Bestand
		WHERE Bestand.Barcodenummer = @Barcode;

	    IF @MediumID IS NULL
		   THROW 50007, 'Barcode nicht erkannt, bitte prüfen! Vorgang wurde abgebrochen.',1;
		    
		-- check if the item is correctly noted as lent by the library user
		IF (SELECT COUNT(ID) FROM @AusleiheKunde) = 0
			THROW 50008, 'Medium nicht als vom Kunden entliehen erkannt, bitte prüfen! Vorgang wurde abgebrochen.',1;

			
		-- check, if the status in the table is set on 'lent'
		SELECT @mediumStatus = Status.StatusBezeichnung
		FROM Status
			INNER JOIN Bestand ON Status.ID = Bestand.StatusID
		WHERE @MediumID = Bestand.ID

		IF @mediumStatus <> 'entliehen'
			SET @feedback = 'Das Medium hat in der Tabelle Bestand nicht den Status "entliehen". Medium wurde zurückgebucht.';

			
		-- selection of the due date of the reversed item
		SELECT @faelligkeit = Faelligkeit
		FROM @AusleiheKunde 
    
		-- check if the item is overdue
		IF(@Rueckgabedatum > @faelligkeit)

		BEGIN
			-- calculation of the number of exceeded days and of the overdue fine
			SET @OverDay = datediff(dd, @Faelligkeit, @Rueckgabedatum)	
			SET @MahnGebuehr = (@OverDay * 0.3) 
			SET @feedback = FORMATMESSAGE ( 'Medium zu spät zurückgegeben, Versäumnisgebühr:  %s . Medium wurde zurückgebucht', CONVERT(varchar, @Mahngebuehr))

		END
	

		-- insert of the date of reversal in table 'Ausleihen'
        SELECT @AusleihID = ID FROM @AusleiheKunde;
		UPDATE  Ausleihen 
		      SET Ausleihen.Rueckgabedatum = @Rueckgabedatum 
			  WHERE @AusleihID = Ausleihen.ID AND Ausleihen.Rueckgabedatum IS NULL;

		-- set status in table 'Bestand' on 'available'
		UPDATE Bestand
			SET Bestand.StatusID = 1
			WHERE Bestand.ID = @mediumID

	END TRY
    
    -- if an error message was triggered, the program jumps at this catch, the process is interrupted and 
    -- an error message is displayed
	BEGIN CATCH
		SET @erfolg = 0;
		SET @feedback = 'Fehler Nr. ' + CONVERT(varchar, ERROR_NUMBER()) + ': ' + ERROR_MESSAGE();
	END CATCH


			  
			 		
RETURN
			 
END