*** Settings ***
Documentation     Template robot main suite.
Library           RPA.Browser
Library           RPA.Robocloud.Secrets
Library           OperatingSystem
Library           Collections
Library           RPA.HTTP
Library           Dialogs
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive

*** Keywords ***
Make Directory Empty
    ${folderName}=    Create List    Input    Output    Temp
    Log To Console    ${folderName}
    FOR    ${item}    IN    @{folderName}
        Log    ${item}
        #Empty Directory    ${CURDIR}${/}${item}
        Remove Directory    ${CURDIR}${/}${item}    True
        Create Directory    ${CURDIR}${/}${item}
    END

*** Keywords ***
Open the robot order website and download the order file
    ${secret}=    Get Secret    roboVariables
    Download    ${secret}[csvURL]    ${CURDIR}${/}Input${/}Orders.csv
    Open Available Browser    ${secret}[rsiURL]
    Maximize Browser Window
    Click Button    //button[contains(text(),'OK')]

*** Keywords ***
Get orders
    ${tables}=    Read Table From Csv    ${CURDIR}${/}Input${/}Orders.csv    header=True
    FOR    ${data}    IN    @{tables}
        Fill the form    ${data}
        Log    ${data}[Head]
        #    Run Keywords    ${data}
    END

*** Keywords ***
Fill the form
    [Arguments]    ${row}
    Select From List By Value    //select[@name="head"]    ${row}[Head]
    Click Element    //input[@value="${row}[Body]"]
    Input Text    //input[@placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    //input[@placeholder="Shipping address"]    ${row}[Address]
    Click Button    //button[@id="preview"]
    sleep    3
    Wait Until Page Contains Element    id:robot-preview-image
    Log    ${row}
    Wait Until Keyword Succeeds    5x    2s    Order page exception
    Download HTML and Create PDF and Take Screenshot    ${row}
    Click Button    id:order-another
    Click Button    //button[contains(text(),'OK')]

*** Keywords ***
Input from User
    ${userInput}=    Get Value From User    Are you ready to see the execution? If yes then type Y in the box.
    [Return]    ${userInput}

*** Keywords ***
Order page exception
    Click Button    id:order
    Page Should Contain    Receipt

*** Keywords ***
Zip Folder
    Archive Folder With Zip    ${CURDIR}${/}Temp    ${CURDIR}${/}Output${/}OrderDetails.zip

*** Keywords ***
Download HTML and Create PDF and Take Screenshot
    [Arguments]    ${data}
    Log    ${data}[Order number]
    Wait Until Element Is Visible    id:receipt
    ${receiptOrderHTML}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receiptOrderHTML}    ${CURDIR}/Temp${/}${data}[Order number].PDF
    Screenshot    id:robot-preview-image    filename=${CURDIR}/Temp${/}${data}[Order number].png
    Sleep    2
    Add Watermark Image To Pdf    ${CURDIR}/Temp${/}${data}[Order number].png    ${CURDIR}/Temp${/}${data}[Order number].PDF    ${CURDIR}/Temp${/}${data}[Order number].PDF
    Remove File    ${CURDIR}/Temp${/}${data}[Order number].png
    Sleep    2

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${userInput}=    Input from User
    IF    "${userInput}"== "Y"
        Make Directory Empty
        Open the robot order website and download the order file
        Get orders
        Zip Folder
        Close Browser
    ELSE
        Log    Have a great day
    END
