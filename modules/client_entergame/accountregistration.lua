local accountRegistrationWindow
local creatingAdditionalCharacter = false

local function registrationError(message)
    displayErrorBox('Cadastro', message)
end

function EnterGame.showAccountCreation(additionalCharacter)
    EnterGame.closeAccountCreation()
    creatingAdditionalCharacter = additionalCharacter == true
    accountRegistrationWindow = g_ui.displayUI('accountregistration')
    accountRegistrationWindow:setText(creatingAdditionalCharacter and 'Criar personagem' or 'Criar conta')
    accountRegistrationWindow:getChildById('createButton'):setText(creatingAdditionalCharacter and 'Criar personagem' or 'Criar conta')
    local sex = accountRegistrationWindow:getChildById('sex')
    sex:addOption('Masculino', 1)
    sex:addOption('Feminino', 0)
    if creatingAdditionalCharacter then
        local email = accountRegistrationWindow:getChildById('email')
        local password = accountRegistrationWindow:getChildById('password')
        local repeatPassword = accountRegistrationWindow:getChildById('repeatPassword')
        email:setText(G.account or '')
        password:setText(G.password or '')
        repeatPassword:setText(G.password or '')
        email:setEnabled(false)
        password:setEnabled(false)
        repeatPassword:setEnabled(false)
        accountRegistrationWindow:getChildById('emailLabel'):hide()
        email:hide()
        accountRegistrationWindow:getChildById('passwordLabel'):hide()
        password:hide()
        accountRegistrationWindow:getChildById('repeatPasswordLabel'):hide()
        repeatPassword:hide()
        accountRegistrationWindow:getChildById('characterNameLabel'):setMarginTop(-114)
        accountRegistrationWindow:setHeight(165)
    else
        accountRegistrationWindow:getChildById('characterNameLabel'):hide()
        accountRegistrationWindow:getChildById('characterName'):hide()
        accountRegistrationWindow:getChildById('sexLabel'):hide()
        sex:hide()
        accountRegistrationWindow:setHeight(190)
    end
    accountRegistrationWindow:show()
    accountRegistrationWindow:raise()
    accountRegistrationWindow:focus()
    accountRegistrationWindow:getChildById(creatingAdditionalCharacter and 'characterName' or 'email'):focus()
end

function EnterGame.closeAccountCreation()
    if accountRegistrationWindow then
        accountRegistrationWindow:destroy()
        accountRegistrationWindow = nil
    end
end

function EnterGame.submitAccountCreation()
    if not accountRegistrationWindow then return end
    local email = accountRegistrationWindow:getChildById('email'):getText():lower()
    local password = accountRegistrationWindow:getChildById('password'):getText()
    local repeated = accountRegistrationWindow:getChildById('repeatPassword'):getText()
    local characterName = accountRegistrationWindow:getChildById('characterName'):getText()
    local sexOption = accountRegistrationWindow:getChildById('sex'):getCurrentOption()
    local sex = sexOption and sexOption.data or 1
    if not email:match('^[^%s@]+@[^%s@]+%.[^%s@]+$') then return registrationError('Informe um email valido.') end
    if #email > 50 then return registrationError('O email deve ter no maximo 50 caracteres.') end
    if #password < 6 or #password > 24 then return registrationError('A senha deve ter entre 6 e 24 caracteres.') end
    if password ~= repeated then return registrationError('As senhas nao conferem.') end
    if creatingAdditionalCharacter and (#characterName < 3 or #characterName > 18 or not characterName:match('^[A-Za-z -]+$')) then
        return registrationError('O nome deve ter de 3 a 18 letras.')
    end
    local command
    if creatingAdditionalCharacter then
        command = '@character|' .. email .. '|' .. sex .. '|' .. characterName
    else
        command = '@create|' .. email
    end
    EnterGame.closeAccountCreation()
    if CharacterList and CharacterList.isVisible and CharacterList.isVisible() then CharacterList.hide(false) end
    EnterGame.loginAccountCommand(command, email, password)
end
