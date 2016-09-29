﻿:Namespace TestVecdbSrv
    ⍝ Call TestVecdbSrv.RunAll to run Server Tests
    ⍝   assumes existence of #.vecdbclt and #.vecdb

    (⎕IO ⎕ML)←1 1
    LOG←1
    toJson←(0 1)∘(7160⌶)
 
    ∇ z←Benchmark;columns;data;options;params;folder;types;name;ix;users;srvproc;clt;TEST;config;db;path
     ⍝ Test database with 2 shards
     ⍝ Also acts as test for add/remove columns
      
      path←Init
      folder←path,'/',(name←'srvtest'),'/'
      ⎕←'Clearing: ',folder
      :Trap 22 ⋄ {}#.vecdb.Delete folder ⋄ :EndTrap
      ⎕MKDIR folder   
      
      :If 0=⎕NC '#.PASS'
         ⎕←'Enter password from mkrom@Mortens-Macbook-Air: '
         #.PASS←⍞
      :EndIf
     
      ⍝ --- Create configuration file ---

      config←CreateBenchConfig folder,'config.json'
      (db (name folder columns types options data))←CreateBenchDB

      ⍝ --- Launch and connect to server, open database ---

      srvproc←#.vecdbsrv.Launch folder 8100      
      #.vecdbclt.Connect '127.0.0.1' 8100 'mkrom'
      db←#.vecdbclt.Open folder
      
      TEST←'Count records'
      assert (≢⊃data)={db.Count} time ⍬ 

      TEST←'Search for all records'
      ix←db.Query time ('Name'((columns⍳⊂'Name')⊃data))⍬ ⍝ Should find everything
      assert(1 2,⍪⍳¨4 1)≡ix

      TEST←'Read it all back'
      assert data≡db.Read time ix columns

      (2⊃data)×←1.1 ⍝ Add 10% to all prices
      TEST←'Update prices'
      z←db.Update time ix 'Price' (2⊃data) ⍝ Update price
      assert data≡db.Read ix columns
      
      ⍝ /// Tests to do:        
      ⍝ Append data - to all and less that all shards
      ⍝ Update multiple columns
      ⍝ Read & update records with shards "out of order"
      ⍝ Read & update not from all shards
      
      ⎕←'Closing down server...'    
      z←db.Shutdown 'Shutting down now!'   
      ⎕DL 3
      :If ~srvproc.HasExited ⋄ srvproc.Kill ⋄ :EndIf
      ⎕DL 3
     
      TEST←'Erase database'
      db←⎕NEW #.vecdb(,⊂folder)
      assert 0={db.Erase}time ⍬
     
      z←'Server Tests Completed'
    ∇
    
    ∇path←Init;source
      ⎕FUNTIE ⎕FNUMS ⋄ ⎕NUNTIE ⎕NNUMS
      :Trap 6 ⋄ source←SALT_Data.SourceFile
      :Else ⋄ source←⎕WSID
      :EndTrap
      path←{(-⌊/(⌽⍵)⍳'\/')↓⍵}source 
      :If 0=⎕NC '#.DRC' ⋄ 'DRC' #.⎕CY 'conga' ⋄ :EndIf
    ∇ 

    ∇ z←RunAll;path;source
      ⎕←ServerBasic
    ∇

    ∇ TestSsh;cmd
      cmd←'RIDE_SPAWNED=1 RIDE_INIT=SERVE::5678 /Applications/Dyalog-15.0.app/Contents/Resources/Dyalog/mapl -q +s'
⍝      ##.APLProcess.NewSshClient '192.168.6.120' 'mkrom' 'c:\docs\personal\macbook-air' cmd
      ##.APLProcess.NewSshClient '192.168.17.129' 'mkrom' 'c:\docs\personal\macbook-air' cmd
    ∇

    ∇ config←CreateBenchConfig filename;db;config;user;vecdbsrv;cmd;host;keyfile
     ⍝ 
      cmd←'RIDE_INIT=SERVE::5678 /Applications/Dyalog-15.0.app/Contents/Resources/Dyalog/mapl'        
      host←'Mortens-Macbook-Air' 
      user←'mkrom'
      keyfile←'c:\docs\personal\macbook_air' 

      user←⎕NS ''
      user.(Name Id Admin)←'mkrom' 1001 1
      vecdbsrv←⎕NS''
      vecdbsrv.Name←'Test Server'
      vecdbsrv.Users←,user
      db←⎕NS''
      db.Folder←folder
      db.Slaves←⎕NS¨2⍴⊂''
      db.Slaves.Shards←,¨1 2 ⍝ Distribution of shards to slave processors
      db.Slaves[1].(Launch←⎕NS '').Type←'local'                                                                
      db.Slaves[2].(Launch←⎕NS '').(Type Host User KeyFile Cmd)←'ssh' host user keyfile cmd
      config←⎕NS''
      config.Server←vecdbsrv
      config.DBs←,db
      (toJson config)⎕NPUT filename
    ∇
       
    ∇ config←CreateTestConfig filename;db;config;user;vecdbsrv
     ⍝ 
      user←⎕NS ''
      user.(Name Id Admin)←'mkrom' 1001 1
      vecdbsrv←⎕NS''
      vecdbsrv.Name←'Test Server'
      vecdbsrv.Users←,user
      db←⎕NS''
      db.Folder←folder
      db.Slaves←⎕NS¨2⍴⊂''
      db.Slaves.Shards←,¨1 2 ⍝ Distribution of shards to slave processors  
      db.Slaves.(Launch←⎕NS '').Type←⊂'local'
      config←⎕NS''
      config.Server←vecdbsrv
      config.DBs←,db
      (toJson config)⎕NPUT filename
    ∇
    
    ∇ (db params)←CreateBenchDB;columns;types;data;options
      columns←'Name' 'Price' 'Flag'
      types←,¨'C' 'F' 'C'
      data←('IBM' 'AAPL' 'MSFT' 'GOOG' 'DYALOG')(160.97 112.6 47.21 531.23 999.99)(5⍴'Buy' 'Sell')
     
      options←⎕NS''
      options.BlockSize←10000
      options.ShardFolders←(folder,'Shard')∘,¨'12'
      options.(ShardFn ShardCols)←'{2-2|⎕UCS ⊃¨⊃⍵}' 1
     
      params←name folder columns types options data
      db←⎕NEW #.vecdb params
      assert (≢⊃data)=db.Count
    ∇

    ∇ (db params)←CreateTestDB;columns;types;data;options
      columns←'Name' 'Price' 'Flag'
      types←,¨'C' 'F' 'C'
      data←('IBM' 'AAPL' 'MSFT' 'GOOG' 'DYALOG')(160.97 112.6 47.21 531.23 999.99)(5⍴'Buy' 'Sell')
     
      options←⎕NS''
      options.BlockSize←10000
      options.ShardFolders←(folder,'Shard')∘,¨'12'
      options.(ShardFn ShardCols)←'{2-2|⎕UCS ⊃¨⊃⍵}' 1
     
      params←name folder columns types options data
      db←⎕NEW #.vecdb params
      assert (≢⊃data)=db.Count
    ∇

    ∇ z←ServerBasic;columns;data;options;params;folder;types;name;ix;users;srvproc;clt;TEST;config;db;path
     ⍝ Test database with 2 shards
     ⍝ Also acts as test for add/remove columns

      path←Init     
      folder←path,'/',(name←'srvtest'),'/'
      ⎕←'Clearing: ',folder
      :Trap 22 ⋄ {}#.vecdb.Delete folder ⋄ :EndTrap
      ⎕MKDIR folder
     
      ⍝ --- Create configuration file ---

      config←CreateBenchConfig folder,'config.json'
      (db (name folder columns types options data))←CreateTestDB

      ⍝ --- Launch and connect to server, open database ---

      srvproc←#.vecdbsrv.Launch folder 8100      
      #.vecdbclt.Connect '127.0.0.1' 8100 'mkrom'
      db←#.vecdbclt.Open folder
      
      TEST←'Count records'
      assert (≢⊃data)={db.Count} time ⍬ 

      TEST←'Search for all records'
      ix←db.Query time ('Name'((columns⍳⊂'Name')⊃data))⍬ ⍝ Should find everything
      assert(1 2,⍪⍳¨4 1)≡ix

      TEST←'Read it all back'
      assert data≡db.Read time ix columns

      (2⊃data)×←1.1 ⍝ Add 10% to all prices
      TEST←'Update prices'
      z←db.Update time ix 'Price' (2⊃data) ⍝ Update price
      assert data≡db.Read ix columns
      
      ⍝ /// Tests to do:        
      ⍝ Append data - to all and less that all shards
      ⍝ Update multiple columns
      ⍝ Read & update records with shards "out of order"
      ⍝ Read & update not from all shards
      
      ⎕←'Closing down server...'    
      z←db.Shutdown 'Shutting down now!'   
      ⎕DL 3
      :If ~srvproc.HasExited ⋄ srvproc.Kill ⋄ :EndIf
      ⎕DL 3
     
      TEST←'Erase database'
      db←⎕NEW #.vecdb(,⊂folder)
      assert 0={db.Erase}time ⍬
     
      z←'Server Tests Completed'
    ∇

    ∇ x←output x
      :If LOG ⋄ ⍞←x ⋄ :EndIf
    ∇

    ∇ r←fmtnum x
    ⍝ Nice formatting of large integers
      r←(↓((⍴x),20)⍴'CI20'⎕FMT⍪,x)~¨' '
    ∇

    assert←{'Assertion failed'⎕SIGNAL(⍵=0)/11}

      time←{⍺←⊣ ⋄ t←⎕AI[3]
          o←output TEST,' ... '
          z←⍺ ⍺⍺ ⍵
          o←output(⍕⎕AI[3]-t),'ms',⎕UCS 10
          z
      }

      expecterror←{
          0::⎕SIGNAL(⍺≡⊃⎕DMX.DM)↓11
          z←⍺⍺ ⍵
          ⎕SIGNAL 11
      } 

:EndNamespace
