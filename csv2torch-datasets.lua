require 'torch'
require 'torch-env'
require 'dataset'
require 'dataset/TableDataset'
require 'csv'
require 'util'
require 'util/arg'
require 'sys'





local function parse_arg(arg, initNLparams)
    local dname, fname = sys.fpath()
    local cmd = torch.CmdLine()
    cmd:text('Options:')
    cmd:option('-csv',      '',     'input csv to convert')
    cmd:option('-out',      '',     'output torch-dataset filename')
    return cmd:parse(arg)
end


local function get_csv(options)
    local csv = Csv(options.csv, "r")
    local alllines = csv:readall()
    csv:close()
    return alllines
end

local function save(csv, options)
    torch.save(options.out, csv)
end

-- function expects a table with lines made of strings
local function csv2tensor(csv)
    local data = torch.Tensor(#csv - 1 ,#csv[1])
    for i = 2,#csv do
        for j = 1,#csv[1] do
            data[i-1][j] = tonumber(csv[i][j])
        end
    end
    return data
end

local function get_dataset(csv, options)
    local tsor = csv2tensor(csv)
    if csv[1][1] == 'label' then 
        local data = tsor:narrow(2, 2, tsor:size(2)-1)
        local class = tsor:narrow(2, 1, 1)
        return dataset.TableDataset({data=data, class=class})
    else
        return dataset.TableDataset({data=tsor})
    end
end


local function main()
    local options = parse_arg(arg, true)
    local csv = get_csv(options)
    dset = get_dataset(csv, options)
    save(dset, options)
end

main()

