//
//  ViewController.m
//  GetSystemAddressBook
//
//  Created by 张一力 on 15/10/19.
//  Copyright © 2015年 张一力. All rights reserved.
//

#import "AddressViewController.h"
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@interface AddressViewController ()<ABPeoplePickerNavigationControllerDelegate>

@end

/** 调取系统通讯录,需导入系统库<AddressBook/AddressBook.h> <AddressBookUI/AddressBookUI.h>
 *  遵循通讯录代理 ABPeoplePickerNavigationControllerDelegate
 *  建议真机调试 模拟器手机号码显示问题
 */

@implementation AddressViewController
{
    ABPeoplePickerNavigationController * picker;
    
    NSString * userName;
    NSString * userPhoneNumber;
    UILabel * nameLabel;
    UILabel * phoneLabel;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self getSystemAddressBook];
    NSLog(@"viewDidLoad");
}
- (void)getSystemAddressBook
{
    UIButton * btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(0.15*[UIScreen mainScreen].bounds.size.width, 250,0.7*[UIScreen mainScreen].bounds.size.width, 100);
    [btn setTitle:@"获取系统通讯录" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:25.0];
    [btn setBackgroundColor:[UIColor blackColor]];
    [btn addTarget:self action:@selector(turnToAddressBook:) forControlEvents:UIControlEventTouchUpInside];
    //切圆角和设置弧度
    btn.layer.cornerRadius = 10;//半径大小
    btn.layer.masksToBounds = YES;//是否切割
    [self.view addSubview:btn];
    
    nameLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, btn.frame.origin.y + btn.frame.size.height, btn.frame.size.width, btn.frame.size.height)];
    nameLabel.textColor = [UIColor whiteColor];
    nameLabel.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:nameLabel];
    
    
    phoneLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, nameLabel.frame.origin.y + nameLabel.frame.size.height, nameLabel.frame.size.width, nameLabel.frame.size.height)];
    phoneLabel.textColor = nameLabel.textColor;
    phoneLabel.backgroundColor = nameLabel.backgroundColor;
    [self.view addSubview:phoneLabel];
    
    
}
/**调取系统电话本*/
- (void)turnToAddressBook:(UIButton *)btn
{
    [self accessTheAddress];
    picker = [[ABPeoplePickerNavigationController alloc]init];
    picker.peoplePickerDelegate = self;
    [self presentViewController:picker animated:YES completion:nil];
    
    
}
#define mark ABPeoplePickerNavigationControllerDelegate(关闭通讯录)
- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}
//ios8 之后弃用
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
    return YES;
}

//ios 8.0之前使用;
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
    CGFloat systemVersion = [[UIDevice currentDevice].systemVersion floatValue];
    
    //联系人name
    NSString * name = (__bridge NSString *)ABRecordCopyCompositeName(person);
    userName = name;
    NSLog(@"取出姓名%@  系统%f",name,systemVersion);
    nameLabel.text = name;
    
    //判断点击区域
    if (property == kABPersonPhoneProperty) {
        //取出当前区域所有数据
        ABMutableMultiValueRef phoneMulti = ABRecordCopyValue(person, kABPersonPhoneProperty);
        //根据点击对应identifieer取出所在索引
        int index = ABMultiValueGetIdentifierAtIndex(phoneMulti, identifier);
        
        NSString * phone = (__bridge NSString *)ABMultiValueCopyValueAtIndex(phoneMulti, index);
        
        //正则过滤取出手机号
        NSString * mobilePhone = [self isMobileNumber:phone];
        userPhoneNumber = mobilePhone;
        NSLog(@"取出手机号%@ 系统%f",mobilePhone,systemVersion);
        phoneLabel.text = mobilePhone;
        
    }
    //关闭通讯录
    [self dismissViewControllerAnimated:YES completion:nil];
    return NO;
    
}
//ios 8.0之后使用
- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker didSelectPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
    
    CGFloat systemVersion = [[UIDevice currentDevice].systemVersion floatValue];
    
    NSString * name = (__bridge NSString *)ABRecordCopyCompositeName(person);
    userName = name;
    NSLog(@"取出姓名%@  系统%f",name,systemVersion);
    nameLabel.text = name;
    
    if (property == kABPersonPhoneProperty) {
        //取出对应区域msg
        ABMutableMultiValueRef phone = ABRecordCopyValue(person, kABPersonPhoneProperty);
        
        int index2 = ABMultiValueGetIdentifierAtIndex(phone, identifier);
        
        NSString * phone1 = (__bridge NSString *)ABMultiValueCopyValueAtIndex(phone,index2);
        
        userPhoneNumber = [self isMobileNumber:phone1];
        NSLog(@"取出手机号%@  系统%f",userPhoneNumber,systemVersion);
        phoneLabel.text = userPhoneNumber;
    }
    
    
}


//获取调用权限(ios6之后)
- (void)accessTheAddress
{
    ABAddressBookRef addRessBook = nil;
    if ([[UIDevice currentDevice].systemName floatValue] >= 6.0) {
        addRessBook = ABAddressBookCreateWithOptions(NULL, NULL);
        //等待用户同意,向下执行
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        ABAddressBookRequestAccessWithCompletion(addRessBook, ^(bool granted, CFErrorRef error) {
            //
        });
        //dispatch_release(sema);
        
    }else{
        
        addRessBook = ABAddressBookCreateWithOptions(NULL, NULL);
    }
    
}

// 正则判断从电话本调取的手机号
- (NSString *)isMobileNumber:(NSString *)mobileNum
{
    
    NSString * MOBILE = @"^(?:\\+?\\d*?\\s*)?(\\d{3})-?(\\d{4})-?(\\d{4})$";
    
    NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:MOBILE options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray * matches = [regex matchesInString:mobileNum options:0 range:NSMakeRange(0, [mobileNum length])];
    NSString * grop = nil;
    NSString * grop1 = nil;
    NSString * grop2 = nil;
    NSString * grop3 = nil;
    for (NSTextCheckingResult * match in matches) {
        grop1 = [mobileNum substringWithRange:[match rangeAtIndex:1]];
        grop2 = [mobileNum substringWithRange:[match rangeAtIndex:2]];
        grop3 = [mobileNum substringWithRange:[match rangeAtIndex:3]];
        
    }
    grop = [[grop1 stringByAppendingString:grop2] stringByAppendingString:grop3];
    NSLog(@"%@",grop);
    if (!grop) {
        return @"无";
    }else{
        return grop;
    }
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
