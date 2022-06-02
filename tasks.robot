*** Settings ***
Documentation       Atividade para certificação Level II Robocorp.
...                 Criar e setar todos diretorios
...                 acessar o site via vault local
...                 Primeira interacao com usuario, digitar OK ou CANCEL
...                 Segunda interacao com usuario, inserir endereco da planilha https://robotsparebinindustries.com/orders.csv
...                 Fechar janela aleatoria
...                 Gerar orders
...                 Visualizar robo
...                 Em caso de falha tentar vinte vezes durante dois segundos cada
...                 Salvar em pdf a receita do robo junto com a imagem dele
...                 Zipar arquivos pdf gerados

Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Desktop
Library             RPA.Archive
Library             OperatingSystem
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault
Library             Dialogs
Library             RPA.Browser.Selenium    auto_close=${FALSE}


*** Variables ***
${PDF_OUTPUT_DIRECTORY}             ${CURDIR}${/}pdf_files
${SCREENSHOT_OUTPUT_DIRECTORY}      ${CURDIR}${/}image_files


*** Tasks ***
Atividade Level II
    Setar todos os diretorios
    Acessar site
    ${userInput}=    Primeira Interacao Usuario ok ou cancel
    IF    "${userInput}"== "ok"
        ${download_url}=    Segunda Interacao Download Arquivo
        ${orders}=    Ler aquivo orders    ${download_url}
        FOR    ${row}    IN    @{orders}
            Fechar janela aleatoria
            Gerar orders    ${row}
            Visualizar o robo
            Wait Until Keyword Succeeds    20x    2s    Submeter order
            ${pdf}=    Salvar a receita em pdf    ${row}[Order number]
            ${screenshot}=    Salvar imagem do robo    ${row}[Order number]
            Mesclar a imagem do robo com a receita e salva em um pdf    ${screenshot}    ${pdf}
            Gerar outro robo
        END
        Zipar pdf gerados
        RPA.Browser.Selenium.Close Browser
        Log    Fim do processo
    ELSE
        RPA.Browser.Selenium.Close Browser
        Log    Quem sabe na proxima
    END


*** Keywords ***
Setar todos os diretorios
    Create Directory    ${PDF_OUTPUT_DIRECTORY}
    Create Directory    ${SCREENSHOT_OUTPUT_DIRECTORY}
    Empty Directory    ${PDF_OUTPUT_DIRECTORY}
    Empty Directory    ${SCREENSHOT_OUTPUT_DIRECTORY}

Acessar site
    ${secret}=    Get Secret    credentials
    RPA.Browser.Selenium.Open Available Browser    ${secret}[browserUrl]

Primeira Interacao Usuario ok ou cancel
    ${userInput}=    Get Value From User
    ...    O processo será iniciado. DIGITE " ok " para continuar ou " cancelar " para finalizar.
    RETURN    ${userInput}

Segunda Interacao Download arquivo
    Add heading
    ...    Para efeito de teste, colar o endereço abaixo no campo: \n "https://robotsparebinindustries.com/orders.csv"
    Add text input    url    label=Download URL
    ${response}=    Run dialog
    RETURN    ${response.url}

Ler aquivo orders
    [Arguments]    ${download_url}
    Download    ${download_url}    target_file=orders.csv    overwrite=True
    ${table}=    Read table from CSV    orders.csv
    RETURN    ${table}

Fechar janela aleatoria
    RPA.Browser.Selenium.Wait And Click Button    css:.btn-warning

Gerar orders
    [Arguments]    ${row}
    RPA.Browser.Selenium.Wait Until Element Is Visible    id:head
    RPA.Browser.Selenium.Select From List By Value    id:head    ${row}[Head]
    RPA.Browser.Selenium.Select Radio Button    body    ${row}[Body]
    RPA.Browser.Selenium.Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    RPA.Browser.Selenium.Input Text    id:address    ${row}[Address]

Visualizar o robo
    Wait Until Keyword Succeeds    20x    2s    RPA.Browser.Selenium.Click Button    //button[@id="preview"]
    RPA.Browser.Selenium.Wait Until Element Is Visible    id:robot-preview-image

Submeter order
    RPA.Browser.Selenium.Page Should Contain Element    id:preview
    RPA.Browser.Selenium.Click Button    //button[@id="order"]
    RPA.Browser.Selenium.Page Should Contain Element    id:receipt

Salvar a receita em pdf
    [Arguments]    ${OrderNr}
    RPA.Browser.Selenium.Wait Until Element Is Visible    id:receipt
    ${receipt}=    RPA.Browser.Selenium.Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt}    ${PDF_OUTPUT_DIRECTORY}${/}${OrderNr}.pdf
    RETURN    ${PDF_OUTPUT_DIRECTORY}${/}${OrderNr}.pdf

Salvar imagem do robo
    [Arguments]    ${OrderNr}
    RPA.Browser.Selenium.Capture Element Screenshot
    ...    id:robot-preview-image
    ...    ${SCREENSHOT_OUTPUT_DIRECTORY}${/}${OrderNr}.png
    RETURN    ${SCREENSHOT_OUTPUT_DIRECTORY}${/}${OrderNr}.png

Mesclar a imagem do robo com a receita e salva em um pdf
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    ${List-png}=    Create List    ${screenshot}
    Add Files To Pdf    ${List-png}    ${pdf}    ${True}
    Close Pdf

Gerar outro robo
    RPA.Browser.Selenium.Click Button    id:order-another

Zipar pdf gerados
    Archive Folder With ZIP
    ...    ${PDF_OUTPUT_DIRECTORY}
    ...    ${OUTPUT_DIR}${/}pdf_archive.zip
    ...    recursive=True
    ...    include=*.pdf
