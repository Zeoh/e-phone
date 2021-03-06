//
//  DBUtil.m
//  ephone
//
//  Created by Jian Liao on 16/4/21.
//  Copyright © 2016年 zeoh. All rights reserved.
//

#import "DBUtil.h"

@implementation DBUtil

static DBUtil * util=nil;

+ (DBUtil *) sharedManager{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        util=[[self alloc]init];
        [util createEditableCopyOfDbIfNeeded];
    });
    
    return util;
}

#pragma mark 数据库存储路径获取
- (NSString *)applicationDocumentsDirectoryFile {
    NSString *docPath=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *dbPath=[docPath stringByAppendingPathComponent:DB_FILE_NAME];
    return dbPath;
}

#pragma mark创建数据库文件
- (void) createEditableCopyOfDbIfNeeded {
    if([self openDB] != SQLITE_OK) {
        NSLog(@"Open DB failed.");
    } else {
        [self createRecentContactsTable];
        [self createContactsTable];
    }
    sqlite3_close(db);
}

#pragma mark 创建通话记录联系人表
- (BOOL) createRecentContactsTable{
    NSString *SQL=[NSString stringWithFormat:
                    @"CREATE TABLE IF NOT EXISTS t_phone_record(id integer primary key autoincrement, name varchar(32), account varchar(32), domain varchar(32), attribution varchar(20), callTime varcher(20), duration char(8), callType int, networkType int, myAccount varchar(32))"];
    BOOL isCreationSuccess = [self execSql:SQL];
    return isCreationSuccess;
    /**
     通话记录数据库表格结构 t_phone_record
     id  int 主键
     name varchar(32) 联系人姓名
     account varchar(32) 通话号码
     domain varchar(32) remote server address
     attribution varchar(20) 号码归属地
     callTime varcher(20) 通话开始时间点   例如 ：2015-03-25 14:00:02
     duration char(8) 通话时长 e.g. 00:02:32
     callType int 接通方式    0:outcoming 1：incoming  2：failed  3：missed
     networkType int 网络类型 0:SIP 1:PSTN
     myAccount varchar(32) 我的当前登录号码
     contactId int foreign key
     **/
}

#pragma mark 查询所有通话记录的方法
- (NSMutableArray *) findAllRecentContactsRecordByLoginMobNum:(NSString *) myAccount{
    NSMutableArray *resultList=[[NSMutableArray alloc]init];
    if ([self openDB]!=SQLITE_OK) {//数据库打开失败
        sqlite3_close(db);
        NSLog(@"数据库打开失败",nil);
    }else{
        NSString *SQL=@"select * from t_phone_record where myAccount=? order by id DESC";
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(db, [SQL UTF8String], -1, &statement, NULL)==SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [myAccount UTF8String], -1, NULL);
            while (sqlite3_step(statement)==SQLITE_ROW) {
                //                NSMutableDictionary *objDict=[[NSMutableDictionary alloc]init];//封装结果成字典对象
                CallRecordModel *recordModel=[[CallRecordModel alloc]init];
                recordModel.dbId=sqlite3_column_int(statement, 0);
                
                //                int  pid=sqlite3_column_int(statement, 0);
                //                [objDict setObject:[NSNumber numberWithInt:pid] forKey:@"id"];
                
                char *name=(char *)sqlite3_column_text(statement, 1);
                //                [objDict setObject:[[NSString alloc ]initWithUTF8String:name] forKey:@"name"];
                if(name) recordModel.name=[[NSString alloc ] initWithUTF8String:name];
                
                char *account=(char *)sqlite3_column_text(statement, 2);
                //                [objDict setObject:[[NSString alloc ]initWithUTF8String:phoneNum] forKey:@"phoneNum"];
                if(account) recordModel.account=[[NSString alloc ] initWithUTF8String:account];
                
                char *domain=(char *)sqlite3_column_text(statement, 3);
                //                [objDict setObject:[[NSString alloc ]initWithUTF8String:location] forKey:@"location"];
                if(domain) recordModel.domain=[[NSString alloc ] initWithUTF8String:domain];
                
                char *attribution=(char *)sqlite3_column_text(statement, 4);
                //                [objDict setObject:[[NSString alloc ]initWithUTF8String:location] forKey:@"location"];
                if(attribution) recordModel.attribution=[[NSString alloc ] initWithUTF8String:attribution];
                
                char  *callTime=(char *)sqlite3_column_text(statement, 5);
                //                [objDict setObject:[[NSString alloc ]initWithUTF8String:call_time] forKey:@"call_time"];
                if(callTime) recordModel.callTime=[[NSString alloc ]initWithUTF8String:callTime];
                
                char  *duration=(char *)sqlite3_column_text(statement, 6);
                //                [objDict setObject:[[NSString alloc ]initWithUTF8String:call_time] forKey:@"call_time"];
                if(duration) recordModel.duration=[[NSString alloc ]initWithUTF8String:duration];
                
                //                int  type=sqlite3_column_int(statement, 5);
                //                [objDict setObject:[NSNumber numberWithInt:type] forKey:@"type"];
                
                CallType callType = atoi((char*)sqlite3_column_text(statement, 7));
                recordModel.callType=callType;
                
                NetworkType networkType=atoi((char*)sqlite3_column_text(statement, 8));
                recordModel.networkType = networkType;
                
                char  *myAccount=(char *)sqlite3_column_text(statement, 9);
                //                [objDict setObject:[[NSString alloc ]initWithUTF8String:myAccount] forKey:@"myAccount"];
                if(myAccount) recordModel.myAccount=[[NSString alloc ]initWithUTF8String:myAccount];
                
                [resultList addObject:recordModel];
            }
        }
        sqlite3_finalize(statement);
        sqlite3_close(db);
    }
    return resultList;
}

#pragma mark 模糊查找通话记录
- (NSMutableArray *) findRecentContactsRecordsByLoginSearchBarContent:(NSString *) searchText withAccount:(NSString*) myAccount {
    NSMutableArray *resultList=[[NSMutableArray alloc]init];
    if ([self openDB]!=SQLITE_OK) {//数据库打开失败
        sqlite3_close(db);
        NSLog(@"数据库打开失败",nil);
    }else{ //and (name like '%?%' or account like =?)
        NSString *SQL=[NSString stringWithFormat:@"select * from t_phone_record where myAccount=? and (name like '%%%@%%' or account like '%%%@%%') order by id DESC", searchText, searchText];
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(db, [SQL UTF8String], -1, &statement, NULL)==SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [myAccount UTF8String], -1, NULL);
            while (sqlite3_step(statement)==SQLITE_ROW) {
                //                NSMutableDictionary *objDict=[[NSMutableDictionary alloc]init];//封装结果成字典对象
                CallRecordModel *recordModel=[[CallRecordModel alloc]init];
                recordModel.dbId=sqlite3_column_int(statement, 0);
                
                //                int  pid=sqlite3_column_int(statement, 0);
                //                [objDict setObject:[NSNumber numberWithInt:pid] forKey:@"id"];
                
                char *name=(char *)sqlite3_column_text(statement, 1);
                //                [objDict setObject:[[NSString alloc ]initWithUTF8String:name] forKey:@"name"];
                if(name) recordModel.name=[[NSString alloc ] initWithUTF8String:name];
                
                char *account=(char *)sqlite3_column_text(statement, 2);
                //                [objDict setObject:[[NSString alloc ]initWithUTF8String:phoneNum] forKey:@"phoneNum"];
                if(account) recordModel.account=[[NSString alloc ] initWithUTF8String:account];
                
                char *domain=(char *)sqlite3_column_text(statement, 3);
                //                [objDict setObject:[[NSString alloc ]initWithUTF8String:location] forKey:@"location"];
                if(domain) recordModel.domain=[[NSString alloc ] initWithUTF8String:domain];
                
                char *attribution=(char *)sqlite3_column_text(statement, 4);
                //                [objDict setObject:[[NSString alloc ]initWithUTF8String:location] forKey:@"location"];
                if(attribution) recordModel.attribution=[[NSString alloc ] initWithUTF8String:attribution];
                
                char  *callTime=(char *)sqlite3_column_text(statement, 5);
                //                [objDict setObject:[[NSString alloc ]initWithUTF8String:call_time] forKey:@"call_time"];
                if(callTime) recordModel.callTime=[[NSString alloc ]initWithUTF8String:callTime];
                
                char  *duration=(char *)sqlite3_column_text(statement, 6);
                //                [objDict setObject:[[NSString alloc ]initWithUTF8String:call_time] forKey:@"call_time"];
                if(duration) recordModel.duration=[[NSString alloc ]initWithUTF8String:duration];
                
                //                int  type=sqlite3_column_int(statement, 5);
                //                [objDict setObject:[NSNumber numberWithInt:type] forKey:@"type"];
                
                CallType callType = atoi((char*)sqlite3_column_text(statement, 7));
                recordModel.callType=callType;
                
                NetworkType networkType=atoi((char*)sqlite3_column_text(statement, 8));
                recordModel.networkType = networkType;
                
                char  *myAccount=(char *)sqlite3_column_text(statement, 9);
                //                [objDict setObject:[[NSString alloc ]initWithUTF8String:myAccount] forKey:@"myAccount"];
                if(myAccount) recordModel.myAccount=[[NSString alloc ]initWithUTF8String:myAccount];
                
                [resultList addObject:recordModel];
            }
        }
        sqlite3_finalize(statement);
        sqlite3_close(db);
    }
    return resultList;
}

#pragma mark 插入通话记录的方法
- (BOOL) insertRecentContactsRecord:(CallRecordModel *) recordModel{
    //                code=[self openDB];
    if ([self openDB] != SQLITE_OK) {//数据库打开失败
        sqlite3_close(db);
        NSLog(@"数据库打开失败",nil);
        return NO;
    }else{
        NSString *SQL=@"insert into t_phone_record(id, name, account, domain, attribution, callTime, duration, callType, networkType, myAccount) values(NULL, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        sqlite3_stmt *statement;
        int code1= sqlite3_prepare_v2(db, [SQL UTF8String], -1, &statement, NULL);
        if (code1==SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [recordModel.name UTF8String], -1, NULL);
            sqlite3_bind_text(statement, 2, [recordModel.account UTF8String], -1, NULL);
            sqlite3_bind_text(statement, 3, [recordModel.domain UTF8String], -1, NULL);
            sqlite3_bind_text(statement, 4, [recordModel.attribution UTF8String], -1, NULL);
            sqlite3_bind_text(statement, 5, [recordModel.callTime UTF8String], -1, NULL);
            sqlite3_bind_text(statement, 6, [recordModel.duration UTF8String], -1, NULL);
            
            sqlite3_bind_int(statement, 7, recordModel.callType);
            sqlite3_bind_int(statement, 8, recordModel.networkType);
            
            sqlite3_bind_text(statement, 9, [recordModel.myAccount UTF8String], -1, NULL);
            
            if (sqlite3_step(statement)!=SQLITE_DONE)
            {
                NSLog(@"通话记录插入失败");
                return NO;
            }
            //删除超过60条的记录
            [self deleteMoreThan60RecentContactRecordWithLoginMobNum:recordModel.myAccount];
        }
        sqlite3_finalize(statement);
        sqlite3_close(db);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"refresh" object:self];
    }
    return YES;
}

#pragma mark 删除指定id通话记录的方法
- (BOOL) deleteRecentContactRecordById:(int) dbId{
    if ([self openDB]!=SQLITE_OK) {//数据库打开失败
        sqlite3_close(db);
        NSLog(@"数据库打开失败",nil);
        return NO;
    }else{
        NSString *SQL=@"delete from t_phone_record where id=?";
        sqlite3_stmt *statement;
        int code1= sqlite3_prepare_v2(db, [SQL UTF8String], -1, &statement, NULL);
        if (code1==SQLITE_OK) {
            sqlite3_bind_int(statement, 1, dbId);
            if (sqlite3_step(statement)!=SQLITE_DONE)
            {
                NSLog(@"通话记录删除失败id=%d",dbId);
                return NO;
            }
            
        }
        sqlite3_finalize(statement);
        sqlite3_close(db);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"recordDeletionSuccess" object:self];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"refresh" object:self];
        return NO;
    }
    return YES;
}

#pragma mark 根据登陆手机号清空该用户通话记录表的方法
- (BOOL) deleteAllRecentContactRecordWithLoginMobNum:(NSString *) myAccount{
    if ([self openDB]!=SQLITE_OK) {//数据库打开失败
        sqlite3_close(db);
        NSLog(@"数据库打开失败",nil);
        return NO;
    }else{
        NSString *SQL=@"delete from t_phone_record where myAccount=?";
        sqlite3_stmt *statement;
        int code2= sqlite3_prepare_v2(db, [SQL UTF8String], -1, &statement, NULL);
        if (code2==SQLITE_OK) {
            sqlite3_bind_text(statement,1, [myAccount UTF8String],-1,NULL);
            if (sqlite3_step(statement)!=SQLITE_DONE) {
                NSLog(@"通话记录清空失败", nil);
                return NO;
            }
            
        }
        sqlite3_finalize(statement);
        sqlite3_close(db);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"refresh" object:self];
    }
    return YES;
}

#pragma mark Private Methods

#pragma mark 打开ephone数据库的方法
-(int) openDB{
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documents = [paths objectAtIndex:0];
//    NSString *dbPath = [documents stringByAppendingPathComponent:@"ephone.sqlite3"];
//    return sqlite3_open([dbPath UTF8String], &db);
    NSString *DBPath=[self applicationDocumentsDirectoryFile];
    return sqlite3_open([DBPath UTF8String], &db);
}

-(BOOL) execSql:(NSString *)sql{
    char *err;
    int rc=sqlite3_exec(db, [sql UTF8String], nil, nil, &err);
    if(rc!=SQLITE_OK) {
        NSLog(@"%@:SQL=%@",@"数据库操作失败",sql);
        return NO;
    } else
        return YES;
}

#pragma mark 删除超过60条的早期通话记录
- (BOOL) deleteMoreThan60RecentContactRecordWithLoginMobNum:(NSString *) mobNum{
    //                code=[self openDB];
    if ([self openDB]!=SQLITE_OK) {//数据库打开失败
        sqlite3_close(db);
        NSLog(@"数据库打开失败",nil);
        return NO;
    }else{
        NSString *SQL=@"delete from t_phone_record where (select count(id) from t_phone_record)> 60 and id in (select id from t_phone_record order by id desc limit (select count(id) from t_phone_record) offset 60 ) and myAccount=?";
        sqlite3_stmt *statement;
        int code2= sqlite3_prepare_v2(db, [SQL UTF8String], -1, &statement, NULL);
        if (code2==SQLITE_OK) {
            sqlite3_bind_text(statement,1, [mobNum UTF8String],-1,NULL);
            if (sqlite3_step(statement)!=SQLITE_DONE) {
                NSLog(@"超量60通话记录清空失败", nil);
                return NO;
            }
            
        }
        sqlite3_finalize(statement);
        sqlite3_close(db);
    }
    return YES;
}

#pragma mark 创建联系人表
- (BOOL) createContactsTable {
    NSString *SQL=[NSString stringWithFormat:
                   @"CREATE TABLE IF NOT EXISTS t_contact(id integer primary key autoincrement, name varchar(32) UNIQUE NOT NULL, account varchar(32) UNIQUE NOT NULL, domain varchar(32), attribution varchar(20), networkType int, myAccount varchar(32))"];
    BOOL isCreationSuccess = [self execSql:SQL];
    return isCreationSuccess;
    /**
     通话记录数据库表格结构 t_phone_record
     id  int 主键
     name varchar(32) 联系人姓名 UNIQUE
     account varchar(32) 通话号码
     domain varchar(32) remote server address
     attribution varchar(20) 号码归属地
     networkType int 网络类型 0:SIP 1:PSTN
     myAccount varchar(32) 我的当前登录号码
     **/
}

#pragma mark 查询联系人通话记录的方法
- (NSMutableArray *) findAllContactsByLoginMobNum:(NSString *) myAccount {
    NSMutableArray *resultList=[[NSMutableArray alloc]init];
    if ([self openDB]!=SQLITE_OK) {//数据库打开失败
        sqlite3_close(db);
        NSLog(@"数据库打开失败",nil);
    }else{
        NSString *SQL=@"select * from t_contact where myAccount=? order by id DESC";
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(db, [SQL UTF8String], -1, &statement, NULL)==SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [myAccount UTF8String], -1, NULL);
            while (sqlite3_step(statement)==SQLITE_ROW) {
                ContactModel *contactModel=[[ContactModel alloc]init];
                contactModel.dbId=sqlite3_column_int(statement, 0);
                
                char *name=(char *)sqlite3_column_text(statement, 1);
                if(name) contactModel.name=[[NSString alloc ] initWithUTF8String:name];
                
                char *account=(char *)sqlite3_column_text(statement, 2);
                if(account) contactModel.account=[[NSString alloc ] initWithUTF8String:account];
                
                char *domain=(char *)sqlite3_column_text(statement, 3);
                if(domain) contactModel.domain=[[NSString alloc ] initWithUTF8String:domain];
                
                char *attribution=(char *)sqlite3_column_text(statement, 4);
                if(attribution) contactModel.attribution=[[NSString alloc ] initWithUTF8String:attribution];
                
                NetworkType networkType=atoi((char*)sqlite3_column_text(statement, 5));
                contactModel.networkType = networkType;
                
                char  *myAccount=(char *)sqlite3_column_text(statement, 9);
                if(myAccount) contactModel.myAccount=[[NSString alloc ]initWithUTF8String:myAccount];
                
                [resultList addObject:contactModel];
            }
        }
        sqlite3_finalize(statement);
        sqlite3_close(db);
    }
    return resultList;
}

#pragma mark 模糊联系人
- (NSMutableArray *) findContactsByLoginSearchBarContent:(NSString *) searchText withAccount:(NSString*) myAccount {
    NSMutableArray *resultList=[[NSMutableArray alloc]init];
    if ([self openDB]!=SQLITE_OK) {//数据库打开失败
        sqlite3_close(db);
        NSLog(@"数据库打开失败",nil);
    }else{ //and (name like '%?%' or account like =?)
        NSString *SQL=[NSString stringWithFormat:@"select * from t_contact where myAccount=? and (name like '%%%@%%' or account like '%%%@%%') order by id DESC", searchText, searchText];
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(db, [SQL UTF8String], -1, &statement, NULL)==SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [myAccount UTF8String], -1, NULL);
            while (sqlite3_step(statement)==SQLITE_ROW) {
                ContactModel *contactModel=[[ContactModel alloc]init];
                contactModel.dbId=sqlite3_column_int(statement, 0);
                
                char *name=(char *)sqlite3_column_text(statement, 1);
                if(name) contactModel.name=[[NSString alloc ] initWithUTF8String:name];
                
                char *account=(char *)sqlite3_column_text(statement, 2);
                if(account) contactModel.account=[[NSString alloc ] initWithUTF8String:account];
                
                char *domain=(char *)sqlite3_column_text(statement, 3);
                if(domain) contactModel.domain=[[NSString alloc ] initWithUTF8String:domain];
                
                char *attribution=(char *)sqlite3_column_text(statement, 4);
                if(attribution) contactModel.attribution=[[NSString alloc ] initWithUTF8String:attribution];
                
                NetworkType networkType=atoi((char*)sqlite3_column_text(statement, 5));
                contactModel.networkType = networkType;
                
                char  *myAccount=(char *)sqlite3_column_text(statement, 6);
                if(myAccount) contactModel.myAccount=[[NSString alloc ]initWithUTF8String:myAccount];
                
                [resultList addObject:contactModel];
            }
        }
        sqlite3_finalize(statement);
        sqlite3_close(db);
    }
    return resultList;
}

#pragma mark 插入联系人的方法
- (BOOL) insertContact:(ContactModel *) contactModel {
    if ([self openDB] != SQLITE_OK) {//数据库打开失败
        sqlite3_close(db);
        NSLog(@"数据库打开失败",nil);
        return NO;
    }else{
        NSString *SQL=@"insert into t_contact(id, name, account, domain, attribution, networkType, myAccount) values(NULL, ?, ?, ?, ?, ?, ?)";
        sqlite3_stmt *statement;
        int code1= sqlite3_prepare_v2(db, [SQL UTF8String], -1, &statement, NULL);
        if (code1==SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [contactModel.name UTF8String], -1, NULL);
            sqlite3_bind_text(statement, 2, [contactModel.account UTF8String], -1, NULL);
            sqlite3_bind_text(statement, 3, [contactModel.domain UTF8String], -1, NULL);
            sqlite3_bind_text(statement, 4, [contactModel.attribution UTF8String], -1, NULL);
            sqlite3_bind_int(statement, 5, contactModel.networkType);
            sqlite3_bind_text(statement, 6, [contactModel.myAccount UTF8String], -1, NULL);
            
            if (sqlite3_step(statement)!=SQLITE_DONE)
            {
                NSLog(@"联系人插入失败");
                [[NSNotificationCenter defaultCenter] postNotificationName:@"contactInsertingFailed" object:self];
                return NO;
            }
        }
        sqlite3_finalize(statement);
        sqlite3_close(db);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"contactInsertingDone" object:self];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"refresh" object:self];
    }
    return YES;
}

#pragma mark 修改联系人的方法
- (BOOL) editContactByID:(ContactModel *)cm withId:(int)dbId {
    if ([self openDB] != SQLITE_OK) {//数据库打开失败
        sqlite3_close(db);
        NSLog(@"数据库打开失败",nil);
        return NO;
    }else{
        NSString *SQL=@"update t_contact set name=?, account=?, attribution=? where id=?";
        sqlite3_stmt *statement;
        int code1= sqlite3_prepare_v2(db, [SQL UTF8String], -1, &statement, NULL);
        if (code1==SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [cm.name UTF8String], -1, NULL);
            sqlite3_bind_text(statement, 2, [cm.account UTF8String], -1, NULL);
            sqlite3_bind_text(statement, 3, [cm.attribution UTF8String], -1, NULL);
            sqlite3_bind_int(statement, 4, dbId);
            
            if (sqlite3_step(statement)!=SQLITE_DONE)
            {
                NSLog(@"联系人修改失败");
                [[NSNotificationCenter defaultCenter] postNotificationName:@"contactEditFailed" object:self];
                return NO;
            }
        }
        sqlite3_finalize(statement);
        sqlite3_close(db);

        [[NSNotificationCenter defaultCenter] postNotificationName:@"contactEditSuccess" object:self];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"refresh" object:self];
    }
    return YES;
}

#pragma mark 删除指定id联系人的方法
- (BOOL) deleteContactById:(int) dbId {
    if ([self openDB]!=SQLITE_OK) {//数据库打开失败
        sqlite3_close(db);
        NSLog(@"数据库打开失败",nil);
        return NO;
    }else{
        NSString *SQL=@"delete from t_contact where id=?";
        sqlite3_stmt *statement;
        int code1= sqlite3_prepare_v2(db, [SQL UTF8String], -1, &statement, NULL);
        if (code1==SQLITE_OK) {
            sqlite3_bind_int(statement, 1, dbId);
            if (sqlite3_step(statement)!=SQLITE_DONE)
            {
                NSLog(@"通话记录删除失败id=%d",dbId);
                return NO;
            }
            
        }
        sqlite3_finalize(statement);
        sqlite3_close(db);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"contactDeletionSuccess" object:self];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"refresh" object:self];
    }
    return YES;
}

#pragma mark 根据登陆账号清空该用户联系人的方法
- (BOOL) deleteAllContactsWithLoginMobNum:(NSString *) myAccount {
    if ([self openDB]!=SQLITE_OK) {//数据库打开失败
        sqlite3_close(db);
        NSLog(@"数据库打开失败",nil);
        return NO;
    }else{
        NSString *SQL=@"delete from t_contact where myAccount=?";
        sqlite3_stmt *statement;
        int code2= sqlite3_prepare_v2(db, [SQL UTF8String], -1, &statement, NULL);
        if (code2==SQLITE_OK) {
            sqlite3_bind_text(statement,1, [myAccount UTF8String],-1,NULL);
            if (sqlite3_step(statement)!=SQLITE_DONE) {
                NSLog(@"通话记录清空失败", nil);
                return NO;
            }
        }
        sqlite3_finalize(statement);
        sqlite3_close(db);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"refresh" object:self];
    }
    return YES;
}

#pragma mark 联系人表有改动时更新通话记录表
- (BOOL) updatePhoneRecords {
    if ([self openDB]!=SQLITE_OK) {//数据库打开失败
        sqlite3_close(db);
        NSLog(@"数据库打开失败",nil);
        return NO;
    }else{
        NSString *SQL1=@"UPDATE t_phone_record SET name = (SELECT t_contact.name FROM t_contact WHERE t_contact.myAccount=t_phone_record.myAccount AND t_contact.account=t_phone_record.account), attribution = (SELECT t_contact.attribution FROM t_contact WHERE t_contact.myAccount=t_phone_record.myAccount AND t_contact.account=t_phone_record.account) WHERE EXISTS (SELECT * FROM t_contact WHERE t_contact.myAccount=t_phone_record.myAccount AND t_contact.account=t_phone_record.account)";
        BOOL isCreationSuccess = [self execSql:SQL1];
        NSString *SQL2=@"UPDATE t_phone_record SET name = '' WHERE NOT EXISTS (SELECT * FROM t_contact WHERE t_contact.myAccount=t_phone_record.myAccount AND t_contact.account=t_phone_record.account)";
        isCreationSuccess = (isCreationSuccess && [self execSql:SQL2]);
        if(isCreationSuccess) {
            sqlite3_close(db);
            [[NSNotificationCenter defaultCenter] postNotificationName:@"refresh" object:self];
            return YES;
        } else{
            NSLog(@"更新失败");
            return NO;
        }
    }
}

#pragma mark 根据号码查询联系人信息
- (ContactModel*) queryContactByAccount:(NSString*) account withAccount:(NSString*) myAccount{
    ContactModel *contactModel=[[ContactModel alloc]init];
    if ([self openDB]!=SQLITE_OK) {//数据库打开失败
        sqlite3_close(db);
        NSLog(@"数据库打开失败",nil);
        return nil;
    }else{
        NSString *SQL=@"select * from t_contact where myAccount=? and account = ? limit 1";
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(db, [SQL UTF8String], -1, &statement, NULL)==SQLITE_OK) {
            sqlite3_bind_text(statement, 1, [myAccount UTF8String], -1, NULL);
            sqlite3_bind_text(statement, 2, [account UTF8String], -1, NULL);
            while (sqlite3_step(statement)==SQLITE_ROW) {
                contactModel.dbId=sqlite3_column_int(statement, 0);
                
                char *name=(char *)sqlite3_column_text(statement, 1);
                if(name) contactModel.name=[[NSString alloc ] initWithUTF8String:name];
                
                char *account=(char *)sqlite3_column_text(statement, 2);
                if(account) contactModel.account=[[NSString alloc ] initWithUTF8String:account];
                
                char *domain=(char *)sqlite3_column_text(statement, 3);
                if(domain) contactModel.domain=[[NSString alloc ] initWithUTF8String:domain];
                
                char *attribution=(char *)sqlite3_column_text(statement, 4);
                if(attribution) contactModel.attribution=[[NSString alloc ] initWithUTF8String:attribution];
                
                NetworkType networkType=atoi((char*)sqlite3_column_text(statement, 5));
                contactModel.networkType = networkType;
                
                char  *myAccount=(char *)sqlite3_column_text(statement, 9);
                if(myAccount) contactModel.myAccount=[[NSString alloc ]initWithUTF8String:myAccount];
            }
        }
        sqlite3_finalize(statement);
        sqlite3_close(db);
    }
    return contactModel;
}

@end
