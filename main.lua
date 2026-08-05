require "import"
import "android.widget.*"
import "android.view.*"
import "android.app.*"
import "android.content.*"
import "android.net.Uri"

local service = service or accessibilityService

local function pesan(teks) Toast.makeText(service, teks, Toast.LENGTH_SHORT).show() end

local function showLocked(builder)
    local dialog = builder.create()
    local window = dialog.getWindow()
    if window then window.setType(WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY) end
    dialog.show()
    return dialog
end

local function copyToJieshuo(text)
    pcall(function()
        if service.copy then
            service.copy(text)
            pesan("Script berhasil disalin ke papan klip Jieshuo!")
        else
            local clipboard = service.getSystemService(Context.CLIPBOARD_SERVICE)
            local clip = ClipData.newPlainText("Jieshuo", text)
            clipboard.setPrimaryClip(clip)
            pesan("Script berhasil disalin ke papan klip Sistem!")
        end
    end)
end

local showMainMenu -- Deklarasi awal

-- Dialog Hasil Khusus Mode 1 (Menampilkan Hasil Potongan Saja & Kode Sisipan Lengkap)
local function showResultDialog(titleText, snippetText, fullText)
    local layRes = LinearLayout(service).setOrientation(1).setPadding(40, 40, 40, 40)
    layRes.addView(TextView(service).setText("Script berhasil diproses! Pilih tindakan di bawah ini:\n"))
    
    local btnCopySnippet = Button(service).setText("Salin Script Potongan Saja")
    local btnCopyFull = Button(service).setText("Salin Script Utuh")
    local btnTestFull = Button(service).setText("Tes Script Utuh (Cek Error)")
    local btnCloseRes = Button(service).setText("Tutup")
    
    layRes.addView(btnCopySnippet)
    layRes.addView(btnCopyFull)
    layRes.addView(btnTestFull)
    layRes.addView(btnCloseRes)
    
    local dRes = showLocked(AlertDialog.Builder(service).setTitle(titleText).setView(layRes))
    
    btnCopySnippet.setOnClickListener(function() copyToJieshuo(snippetText) end)
    btnCopyFull.setOnClickListener(function() copyToJieshuo(fullText) end)
    btnTestFull.setOnClickListener(function()
        local func, err = load(fullText)
        if func then
            local ok, runErr = pcall(func)
            if ok then pesan("Sukses: Script berjalan tanpa error!") else pesan("Runtime Error:\n" .. tostring(runErr)) end
        else pesan("Syntax Error:\n" .. tostring(err)) end
    end)
    btnCloseRes.setOnClickListener(function() dRes.dismiss() end)
end

-- Dialog Hasil Khusus Mode 2
local function showMode2ResultDialog(titleText, fullText)
    local layRes = LinearLayout(service).setOrientation(1).setPadding(40, 40, 40, 40)
    layRes.addView(TextView(service).setText("Script berhasil digenerate!\n"))
    
    local btnCopy = Button(service).setText("Salin Script")
    local btnTest = Button(service).setText("Tes Script (Cek Error)")
    local btnBatal = Button(service).setText("Batal")
    
    layRes.addView(btnCopy)
    layRes.addView(btnTest)
    layRes.addView(btnBatal)
    
    local dRes = showLocked(AlertDialog.Builder(service).setTitle(titleText).setView(layRes))
    
    btnCopy.setOnClickListener(function() copyToJieshuo(fullText) end)
    btnTest.setOnClickListener(function()
        local func, err = load(fullText)
        if func then
            local ok, runErr = pcall(func)
            if ok then pesan("Sukses: Script berjalan tanpa error!") else pesan("Runtime Error:\n" .. tostring(runErr)) end
        else pesan("Syntax Error:\n" .. tostring(err)) end
    end)
    btnBatal.setOnClickListener(function() 
        dRes.dismiss()
        showMainMenu()
    end)
end

-- ==========================================
-- MODE 1: Input Script Potongan & Pengaturan Developer
-- ==========================================
local function runMode1()
    local injLayout = LinearLayout(service).setOrientation(1).setPadding(30, 30, 30, 30)
    local scrollInj = ScrollView(service)
    local innerInj = LinearLayout(service).setOrientation(1)
    scrollInj.addView(innerInj)
    injLayout.addView(scrollInj)
    
    innerInj.addView(TextView(service).setText("Tempel/Masukkan Script Potongan Tombol Target:\n(Contoh: addBtn(\"Simpan\", function() ... end))"))
    local etSnippetInput = EditText(service)
    etSnippetInput.setMinLines(5)
    etSnippetInput.setGravity(Gravity.TOP)
    etSnippetInput.setHint("Tempel potongan kode tombol di sini...")
    innerInj.addView(etSnippetInput)
    
    innerInj.addView(TextView(service).setText("Judul tombol pengembang (contoh: Tentang):"))
    local etButtonTitle = EditText(service).setText("Tentang")
    innerInj.addView(etButtonTitle)
    
    innerInj.addView(TextView(service).setText("Judul dialog (contoh: Pengembang):"))
    local etDlgTitle = EditText(service).setText("Pengembang")
    innerInj.addView(etDlgTitle)
    
    innerInj.addView(TextView(service).setText("Nama pengembang:"))
    local etDevName = EditText(service).setText("Developer by al-kausar")
    innerInj.addView(etDevName)
    
    innerInj.addView(TextView(service).setText("Pusat Tambah Konten (Teks / Tombol Join):"))
    
    local layoutDynamicItems = LinearLayout(service).setOrientation(1)
    innerInj.addView(layoutDynamicItems)

    local contentEntries = {}

    local function renderContentEntriesList()
        layoutDynamicItems.removeAllViews()
        for idx, item in ipairs(contentEntries) do
            local rowBox = LinearLayout(service).setOrientation(0)
            local descText = TextView(service)
            if item.type == "text" then
                descText.setText("[" .. idx .. "] Teks: " .. item.val)
            else
                descText.setText("[" .. idx .. "] Tombol Join: " .. item.name .." (" .. item.link .. ")")
            end
            descText.setLayoutParams(LinearLayout.LayoutParams(0, -2, 1))
            rowBox.addView(descText)

            local btnDel = Button(service).setText("Hapus")
            btnDel.setOnClickListener(function()
                table.remove(contentEntries, idx)
                renderContentEntriesList()
                pesan("Elemen dihapus dari daftar!")
            end)
            rowBox.addView(btnDel)
            layoutDynamicItems.addView(rowBox)
        end
    end

    innerInj.addView(TextView(service).setText("Ketik Teks Baru:"))
    local etMultiline = EditText(service).setMinLines(2).setGravity(Gravity.TOP).setHint("Tulis teks tambahan...")
    innerInj.addView(etMultiline)
    
    local btnAddMulti = Button(service).setText("Tambahkan Teks Berbaris")
    innerInj.addView(btnAddMulti)
    
    btnAddMulti.setOnClickListener(function()
        local t = etMultiline.getText().toString()
        if t ~= "" then
            table.insert(contentEntries, {type = "text", val = t})
            etMultiline.setText("")
            renderContentEntriesList()
            pesan("Teks berhasil dimasukkan ke antrean bawah!")
        else
            pesan("Kotak teks masih kosong!")
        end
    end)

    innerInj.addView(TextView(service).setText("Nama Tombol Join (contoh: Grup Telegram/WA):"))
    local etJoinBtnName = EditText(service).setHint("Nama tombol...")
    innerInj.addView(etJoinBtnName)

    innerInj.addView(TextView(service).setText("Link / URL:"))
    local etJoinLink = EditText(service).setHint("https://...")
    innerInj.addView(etJoinLink)

    local btnAddJoin = Button(service).setText("Tambahkan Tombol Join Baru")
    innerInj.addView(btnAddJoin)

    btnAddJoin.setOnClickListener(function()
        local jName = etJoinBtnName.getText().toString()
        local jLink = etJoinLink.getText().toString()
        if jName ~= "" and jLink ~= "" then
            table.insert(contentEntries, {type = "join", name = jName, link = jLink})
            etJoinBtnName.setText("")
            etJoinLink.setText("")
            renderContentEntriesList()
            pesan("Tombol join berhasil dimasukkan ke antrean bawah!")
        else
            pesan("Nama dan Link harus diisi!")
        end
    end)

    innerInj.addView(TextView(service).setText("Hak Cipta (Paling Bawah):"))
    local etCopyright = EditText(service).setText("Copyright 2026 al-kausar. All rights reserved.")
    innerInj.addView(etCopyright)

    innerInj.addView(TextView(service).setText("Tombol tutup dialog:"))
    local etCloseName = EditText(service).setText("Tutup")
    innerInj.addView(etCloseName)
    
    local rowBtn2 = LinearLayout(service).setOrientation(0)
    local btnBuildFinal = Button(service).setText("Proses & Bersihkan Script")
    local btnTutupForm = Button(service).setText("Batal")
    rowBtn2.addView(btnBuildFinal)
    rowBtn2.addView(btnTutupForm)
    innerInj.addView(rowBtn2)
    
    local dInj = showLocked(AlertDialog.Builder(service).setTitle("Mode 1: Input Potongan Script").setView(injLayout))
    btnTutupForm.setOnClickListener(function() 
        dInj.dismiss()
        showMainMenu()
    end)
    
    btnBuildFinal.setOnClickListener(function()
        local rawSnippet = etSnippetInput.getText().toString()
        if rawSnippet == "" then
            pesan("Kotak script potongan belum diisi!")
            return
        end

        local lastT = etMultiline.getText().toString()
        if lastT ~= "" then table.insert(contentEntries, {type = "text", val = lastT}) end
        
        local lastJName = etJoinBtnName.getText().toString()
        local lastJLink = etJoinLink.getText().toString()
        if lastJName ~= "" and lastJLink ~= "" then table.insert(contentEntries, {type = "join", name = lastJName, link = lastJLink}) end

        local finalBtnTitle = etButtonTitle.getText().toString()
        local dTitle = etDlgTitle.getText().toString()
        local devN = etDevName.getText().toString()
        local cRight = etCopyright.getText().toString()
        local cName = etCloseName.getText().toString()
        
        -- Pembersihan Otomatis Kata "function" di awal baris jika ada
        local cleanSnippet = rawSnippet:gsub("^%s*function%s*%(%s*%)", ""):gsub("^%s*function%s+[a-zA-Z0-9_]+%s*%(%s*%)", ""):gsub("^%s+", ""):gsub("%s+$", "")

        local devDialogInnerCode = [[
local devLay = LinearLayout(service).setOrientation(1).setPadding(40, 40, 40, 40)
devLay.addView(TextView(service).setText("]] .. devN .. [["))
]]
        
        local joinEntriesForCode = {}
        for _, item in ipairs(contentEntries) do
            if item.type == "text" then
                devDialogInnerCode = devDialogInnerCode .. [[devLay.addView(TextView(service).setText("]] .. item.val .. [["))
]]
            elseif item.type == "join" then
                table.insert(joinEntriesForCode, {name = item.name, link = item.link})
            end
        end

        devDialogInnerCode = devDialogInnerCode .. [[devLay.addView(TextView(service).setText("]] .. cRight .. [["))
]]

        if #joinEntriesForCode > 0 then
            devDialogInnerCode = devDialogInnerCode .. [[
local rowJoin = LinearLayout(service).setOrientation(0)
devLay.addView(rowJoin)
]]
            for _, jData in ipairs(joinEntriesForCode) do
                devDialogInnerCode = devDialogInnerCode .. [[
local btnJoin = Button(service).setText("]] .. jData.name .. [[")
btnJoin.setOnClickListener(function()
  local i = Intent(Intent.ACTION_VIEW, Uri.parse("]] .. jData.link .. [["))
  i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
  service.startActivity(i)
end)
rowJoin.addView(btnJoin)
]]
            end
        end

        devDialogInnerCode = devDialogInnerCode .. [[
local devDialogB = AlertDialog.Builder(service).setTitle("]] .. dTitle .. [[").setView(devLay)
devDialogB.setNegativeButton("]] .. cName .. [[", nil)
showLocked(devDialogB)
]]
        
        local generatedButtonCode = string.format('local btnDev = Button(service)\nbtnDev.setText("%s")\nbtnDev.setOnClickListener(function()\n%s\nend)\npcall(function(),  local targetLay = lay or inner or root or contentLayout or linear or container or mainLayout\n  if not targetLay and activity and activity.ContentView then targetLay = activity.ContentView end\n  if targetLay then targetLay.addView(btnDev) if targetLay.invalidate then targetLay.invalidate() end end\nend)', finalBtnTitle, devDialogInnerCode)

        -- Gabungkan script potongan bersih + tombol developer baru
        local finalCleanSnippet = cleanSnippet .. "\n\n" .. generatedButtonCode
        local finalCompleteSimulatedScript = cleanSnippet .. "\n\n" .. generatedButtonCode

        dInj.dismiss()
        showResultDialog("Hasil Mode 1", finalCleanSnippet, finalCompleteSimulatedScript)
    end)
end

-- ==========================================
-- MODE 2: Pembuatan Script Lua
-- ==========================================
local function runMode2()
    local rootLay = LinearLayout(service).setOrientation(1).setPadding(30, 30, 30, 30)
    local scroll = ScrollView(service)
    local inner = LinearLayout(service).setOrientation(1)
    scroll.addView(inner)
    rootLay.addView(scroll)

    inner.addView(TextView(service).setText("Nama Dialog Script Utama:"))
    local etMainTitle = EditText(service).setText("Menu Ekstensi")
    inner.addView(etMainTitle)
    
    local scriptEntries = {}
    
    inner.addView(TextView(service).setText("\nNama Fungsi:"))
    local etFuncName = EditText(service).setHint("Contoh: Fitur Salin")
    inner.addView(etFuncName)

    inner.addView(TextView(service).setText("Script Lua:"))
    local etScriptContent = EditText(service).setMinLines(4).setGravity(Gravity.TOP).setHint("Masukkan script disini...")
    inner.addView(etScriptContent)

    local btnAddScript = Button(service).setText("Tambah Script ke Daftar Menu")
    inner.addView(btnAddScript)
    
    local chkCloseDialog = CheckBox(service).setText("Tutup dialog saat menjalankan script")
    chkCloseDialog.setChecked(true)
    inner.addView(chkCloseDialog)

    btnAddScript.setOnClickListener(function()
        local fName = etFuncName.getText().toString()
        local fCode = etScriptContent.getText().toString()
        if fName == "" or fCode == "" then
            pesan("Nama fungsi dan isi script tidak boleh kosong!")
            return
        end
        table.insert(scriptEntries, {name = fName, code = fCode})
        etFuncName.setText("")
        etScriptContent.setText("")
        pesan("Berhasil! '" .. fName .. "' ditambahkan ke antrean memori.")
    end)

    inner.addView(TextView(service).setText("\n====================\n"))

    local chkDevMenu = CheckBox(service).setText("Aktifkan Menu Pengembang")
    inner.addView(chkDevMenu)
    
    local devContainer = LinearLayout(service).setOrientation(1)
    devContainer.setVisibility(View.GONE)
    
    devContainer.addView(TextView(service).setText("Judul Tombol Developer:"))
    local etBtnDev = EditText(service).setText("Tentang Pengembang")
    devContainer.addView(etBtnDev)
    
    devContainer.addView(TextView(service).setText("Nama Developer:"))
    local etDevName = EditText(service).setText("Developer by al-kausar")
    devContainer.addView(etDevName)
    
    devContainer.addView(TextView(service).setText("Pusat Tambah Konten (Teks / Tombol Join):"))
    
    local layoutDynamicItemsDev = LinearLayout(service).setOrientation(1)
    devContainer.addView(layoutDynamicItemsDev)

    local contentEntriesDev = {}

    local function renderContentEntriesDevList()
        layoutDynamicItemsDev.removeAllViews()
        for idx, item in ipairs(contentEntriesDev) do
            local rowBox = LinearLayout(service).setOrientation(0)
            local descText = TextView(service)
            if item.type == "text" then
                descText.setText("[" .. idx .. "] Teks: " .. item.val)
            else
                descText.setText("[" .. idx .. "] Tombol Join: " .. item.name .. " (" .. item.link .. ")")
            end
            descText.setLayoutParams(LinearLayout.LayoutParams(0, -2, 1))
            rowBox.addView(descText)

            local btnDel = Button(service).setText("Hapus")
            btnDel.setOnClickListener(function()
                table.remove(contentEntriesDev, idx)
                renderContentEntriesDevList()
                pesan("Elemen dihapus dari daftar!")
            end)
            rowBox.addView(btnDel)
            layoutDynamicItemsDev.addView(rowBox)
        end
    end

    devContainer.addView(TextView(service).setText("Ketik Teks Baru:"))
    local etMultilineDev = EditText(service).setMinLines(2).setGravity(Gravity.TOP).setHint("Tulis teks tambahan...")
    devContainer.addView(etMultilineDev)
    
    local btnAddMultiDev = Button(service).setText("Tambahkan Teks Berbaris")
    devContainer.addView(btnAddMultiDev)

    btnAddMultiDev.setOnClickListener(function()
        local t = etMultilineDev.getText().toString()
        if t ~= "" then
            table.insert(contentEntriesDev, {type = "text", val = t})
            etMultilineDev.setText("")
            renderContentEntriesDevList()
            pesan("Teks berhasil dimasukkan ke antrean bawah!")
        else
            pesan("Kotak teks masih kosong!")
        end
    end)
    
    devContainer.addView(TextView(service).setText("Nama Tombol Join (contoh: Grup Telegram/WA):"))
    local etJoinBtnNameDev = EditText(service).setHint("Nama tombol...")
    devContainer.addView(etJoinBtnNameDev)

    devContainer.addView(TextView(service).setText("Link / URL:"))
    local etJoinLinkDev = EditText(service).setHint("https://...")
    devContainer.addView(etJoinLinkDev)

    local btnAddJoinDev = Button(service).setText("Tambahkan Tombol Join Baru")
    devContainer.addView(btnAddJoinDev)

    btnAddJoinDev.setOnClickListener(function()
        local jName = etJoinBtnNameDev.getText().toString()
        local jLink = etJoinLinkDev.getText().toString()
        if jName ~= "" and jLink ~= "" then
            table.insert(contentEntriesDev, {type = "join", name = jName, link = jLink})
            etJoinBtnNameDev.setText("")
            etJoinLinkDev.setText("")
            renderContentEntriesDevList()
            pesan("Tombol join berhasil dimasukkan ke antrean bawah!")
        else
            pesan("Nama dan Link harus diisi!")
        end
    end)

    devContainer.addView(TextView(service).setText("Teks Hak Cipta (Paling Bawah):"))
    local etCopyright = EditText(service).setText("Copyright 2026 al-kausar. All rights reserved.")
    devContainer.addView(etCopyright)
    
    inner.addView(devContainer)
    
    chkDevMenu.setOnClickListener(function()
        if chkDevMenu.isChecked() then devContainer.setVisibility(View.VISIBLE) else devContainer.setVisibility(View.GONE) end
    end)

    local rowBtn = LinearLayout(service).setOrientation(0)
    local btnGen = Button(service).setText("Generate Script")
    local btnTutup = Button(service).setText("Batal")
    rowBtn.addView(btnGen)
    rowBtn.addView(btnTutup)
    inner.addView(rowBtn)

    local dMode2 = showLocked(AlertDialog.Builder(service).setTitle("Pembuat Script Lua").setView(rootLay))
    
    btnTutup.setOnClickListener(function() 
        dMode2.dismiss()
        showMainMenu()
    end)
    
    btnGen.setOnClickListener(function()
        local lastFName = etFuncName.getText().toString()
        local lastFCode = etScriptContent.getText().toString()
        if lastFName ~= "" and lastFCode ~= "" then
            table.insert(scriptEntries, {name = lastFName, code = lastFCode})
            etFuncName.setText("")
            etScriptContent.setText("")
        end

        local lastT = etMultilineDev.getText().toString()
        if lastT ~= "" then table.insert(contentEntriesDev, {type = "text", val = lastT}) end

        local lastJName = etJoinBtnNameDev.getText().toString()
        local lastJLink = etJoinLinkDev.getText().toString()
        if lastJName ~= "" and lastJLink ~= "" then table.insert(contentEntriesDev, {type = "join", name = lastJName, link = lastJLink}) end

        if #scriptEntries == 0 then
            pesan("Belum ada script yang ditambahkan ke menu!")
            return
        end

        local mTitle = etMainTitle.getText().toString()
        local useDev = chkDevMenu.isChecked()
        local autoClose = chkCloseDialog.isChecked()
        
        local generatedCode = [[
require "import"
import "android.widget.*"
import "android.view.*"
import "android.app.*"
import "android.content.*"
import "android.net.Uri"

local service = service or accessibilityService
]]
        for i, entry in ipairs(scriptEntries) do
            generatedCode = generatedCode .. [[

-- Fungsi: ]] .. entry.name .. [[

local function aksi_fungsi_]] .. i .. [[()
  pcall(function()
]] .. entry.code .. [[

  end)
end
]]
        end
        
        if useDev then
            local dName = etDevName.getText().toString()
            local dCopy = etCopyright.getText().toString()
            
            generatedCode = generatedCode .. [[

-- Menu Developer
local function tampilkanMenuDeveloper()
  local devLay = LinearLayout(service).setOrientation(1).setPadding(40,40,40,40)
  devLay.addView(TextView(service).setText("]] .. dName .. [["))
]]
            
            local joinEntriesDevForCode = {}
            for _, item in ipairs(contentEntriesDev) do
                if item.type == "text" then
                    generatedCode = generatedCode .. [[  devLay.addView(TextView(service).setText("]] .. item.val .. [["))
]]
                elseif item.type == "join" then
                    table.insert(joinEntriesDevForCode, {name = item.name, link = item.link})
                end
            end

            generatedCode = generatedCode .. [[  devLay.addView(TextView(service).setText("]] .. dCopy .. [["))
]]

            if #joinEntriesDevForCode > 0 then
                generatedCode = generatedCode .. [[
  local rowJoin = LinearLayout(service).setOrientation(0)
  devLay.addView(rowJoin)
]]
                for _, jDataDev in ipairs(joinEntriesDevForCode) do
                    generatedCode = generatedCode .. [[
  local btnJoin = Button(service).setText("]] .. jDataDev.name .. [[")
  btnJoin.setOnClickListener(function()
    local i = Intent(Intent.ACTION_VIEW, Uri.parse("]] .. jDataDev.link .. [["))
    i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    service.startActivity(i)
  end)
  rowJoin.addView(btnJoin)
]]
                end
            end

            generatedCode = generatedCode .. [[
  local devDialog = AlertDialog.Builder(service).setTitle("Pengembang").setView(devLay)
  devDialog.setNegativeButton("Tutup", nil)
  
  local d = devDialog.create()
  local w = d.getWindow()
  if w then w.setType(WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY) end
  d.show()
end
]]
        end
        
        generatedCode = generatedCode .. [[

local mainLay = LinearLayout(service).setOrientation(1).setPadding(40,40,40,40)
local mainDialogB = AlertDialog.Builder(service).setTitle("]] .. mTitle .. [[").setView(mainLay)
local mainDialog = mainDialogB.create()
local mw = mainDialog.getWindow()
if mw then mw.setType(WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY) end

]]
        for i, entry in ipairs(scriptEntries) do
            generatedCode = generatedCode .. [[
local btn_]] .. i .. [[ = Button(service).setText("]] .. entry.name .. [[")
mainLay.addView(btn_]] .. i .. [[)
btn_]].. i .. [[.setOnClickListener(function()
]]
            if autoClose then
                generatedCode = generatedCode .. [[  mainDialog.dismiss()
]]
            end
            generatedCode = generatedCode .. [[  aksi_fungsi_]] .. i .. [[()
end)
]]
        end

        if useDev then
            local bDevText = etBtnDev.getText().toString()
            generatedCode = generatedCode .. [[

local btnDev = Button(service).setText("]] .. bDevText .. [[")
mainLay.addView(btnDev)
btnDev.setOnClickListener(function()
  tampilkanMenuDeveloper()
end)
]]
        end
        
        generatedCode = generatedCode .. [[

local btnClose = Button(service).setText("Tutup")
mainLay.addView(btnClose)
btnClose.setOnClickListener(function()
  mainDialog.dismiss()
end)

mainDialog.show()
]]
        dMode2.dismiss()
        pesan("Script hasil generate berhasil dibuat!")
        showMode2ResultDialog("Hasil Mode 2", generatedCode)
    end)
end

-- ==========================================
-- MENU UTAMA
-- ==========================================
function showMainMenu()
    local root = LinearLayout(service).setOrientation(1).setPadding(40, 40, 40, 40)
    local title = TextView(service).setText("Injector Menu Developer")
    title.setTextSize(18)
    title.setPadding(0, 0, 0, 30)
    root.addView(title)
    
    local btnMode1 = Button(service).setText("Mode 1: Analisa & Inject Script")
    local btnMode2Real = Button(service).setText("Mode 2: Pembuatan Script Lua")
    local btnTutup = Button(service).setText("Tutup Alat")
    
    root.addView(btnMode1)
    root.addView(btnMode2Real)
    root.addView(btnTutup)
    
    local dMain = showLocked(AlertDialog.Builder(service).setView(root))
    
    btnMode1.setOnClickListener(function() dMain.dismiss(); runMode1() end)
    btnMode2Real.setOnClickListener(function() dMain.dismiss(); runMode2() end)
    btnTutup.setOnClickListener(function() dMain.dismiss(); pesan("Alat Ditutup.") end)
end

showMainMenu()