*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Desktop
Library           RPA.Archive
Library           OperatingSystem
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault

*** Variables ***
${PDF_OUTPUT_DIRECTORY}    ${CURDIR}${/}pdf_files
${SCREENSHOT_OUTPUT_DIRECTORY}    ${CURDIR}${/}image_files

*** Tasks ***
Order robots from RobotSpareBin Industries Incp
    Set up directories
    Open the robot order website
    ${download_url}=    Download url from user
    ${orders}=    Get orders    ${download_url}
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds    20x    2s    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close Browser

*** Keywords ***
Set up directories
    Create Directory    ${PDF_OUTPUT_DIRECTORY}
    Create Directory    ${SCREENSHOT_OUTPUT_DIRECTORY}
    Empty Directory    ${PDF_OUTPUT_DIRECTORY}
    Empty Directory    ${SCREENSHOT_OUTPUT_DIRECTORY}

Open the robot order website
    ${secret}=    Get Secret    credentials
    Open Available Browser    ${secret}[browserUrl]

Download url from user
    Add text input    url    label=Download URL
    ${response}=    Run dialog
    [Return]    ${response.url}

Get orders
    [Arguments]    ${download_url}
    Download    ${download_url}    target_file=orders.csv    overwrite=True
    ${table}=    Read table from CSV    orders.csv
    [Return]    ${table}

Close the annoying modal
    Wait And Click Button    css:.btn-warning

Fill the form
    [Arguments]    ${row}
    Wait Until Element Is Visible    id:head
    Select From List By Value    id:head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    Input Text    id:address    ${row}[Address]

Preview the robot
    Wait Until Keyword Succeeds    20x    2s    Click Button    id:preview
    Wait Until Element Is Visible    id:robot-preview-image

Submit the order
    Page Should Contain Element    id:preview
    Click Button    id:order
    Page Should Contain Element    id:receipt

 Store the receipt as a PDF file
    [Arguments]    ${OrderNr}
    Wait Until Element Is Visible    id:receipt
    ${receipt}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt}    ${PDF_OUTPUT_DIRECTORY}${/}${OrderNr}.pdf
    [Return]    ${PDF_OUTPUT_DIRECTORY}${/}${OrderNr}.pdf

Take a screenshot of the robot
    [Arguments]    ${OrderNr}
    #Sleep    5sec
    Capture Element Screenshot    id:robot-preview-image    ${SCREENSHOT_OUTPUT_DIRECTORY}${/}${OrderNr}.png
    [Return]    ${SCREENSHOT_OUTPUT_DIRECTORY}${/}${OrderNr}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    ${List-png}=    Create List    ${screenshot}
    Add Files To Pdf    ${List-png}    ${pdf}    ${True}
    Close Pdf

Go to order another robot
    Click Button    id:order-another

Create a ZIP file of the receipts
    Archive Folder With ZIP    ${PDF_OUTPUT_DIRECTORY}    ${OUTPUT_DIR}${/}pdf_archive.zip    recursive=True    include=*.pdf
