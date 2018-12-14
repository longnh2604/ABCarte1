//
//  DevStatusCheck.m
//  iPadCamera
//
//  Created by 西島和彦 on 2014/10/23.
//
//

#import "DevStatusCheck.h"

@implementation DevStatusCheck

+ (unsigned int)getFreeMemory {
    
    mach_port_t host_port;
    mach_msg_type_number_t host_size;
    vm_size_t pagesize;
    
    host_port = mach_host_self();
    host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    host_page_size(host_port, &pagesize);
    vm_statistics_data_t vm_stat;
    
    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS) {
        NSLog(@"Failed to fetch vm statistics");
        return 0;
    }
    
    natural_t mem_free = vm_stat.free_count * (int)pagesize;
    
    return (unsigned int)mem_free;
}

@end
