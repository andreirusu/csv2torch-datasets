#!/usr/bin/env torch
require 'torch'
require 'torch-env'
require 'dataset'
require 'dataset/TableDataset'
require 'Csv'
require 'util'
require 'util/arg'
require 'sys'





local function parse_arg(arg, initNLparams)
    local dname, fname = sys.fpath()
    local cmd = torch.CmdLine()
    cmd:text('Options:')
    cmd:option('-csv',      '',     'input csv to convert')
    cmd:option('-out',      '',     'output torch-dataset filename')
    cmd:option('-N',        20000,  'size of block to read at once')

    return cmd:parse(arg)
end


local function get_csv(options)
    local csv = Csv(options.csv, "r")
    return csv
end

local function save(data, options)
    torch.save(options.out, data)
end

local function get_N_samples(csv, options)
    local data = torch.Tensor(options.N, options.nfeatures)
    local i = 1
    local line 
    while i <= options.N do
        line = csv:read()
        if not line then break end
        for j = 1,options.nfeatures do
            data[i][j] = tonumber(line[j])
        end
        i = i + 1
    end
    i = i-1
    data = data:narrow(1, 1, i)
    assert(not line, 'Skipped all but the first '..options.N..' samples! Increase buffer size to fit all your data, using the -N command line option.')
    return data
end


local function get_dataset(csv, options) 

    -- get header
    local header = csv:read()
    options.nfeatures = #header
   
    local data = get_N_samples(csv, options)
    local class
    
    -- separate labels from data
    if header[1] == 'label' then 
        class = data:narrow(2, 1, 1)
        data = data:narrow(2, 2, data:size(2)-1)
    end

    data = data:clone()
    
    if class then 
        class = class:clone()
    end

    return dataset.TableDataset({data=data, class=class})
end


local function main()
    local options = parse_arg(arg, true)
    local csv = get_csv(options)
    dset = get_dataset(csv, options)
    save(dset, options)
end

main()

